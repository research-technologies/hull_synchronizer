class IngestWorkflowMonitorJob < ActiveJob::Base
  queue_as :workflow_monitor
  attr_accessor :flow

  def perform(workflow_id)
    @flow = IngestWorkflow.find(workflow_id)
    return if stop?
    continue if retry?
    retry_later if retry?
  end

  def continue
    flow.continue
    sleep(5) # give the continue chance to complete
    flow.reload
  end

  def retry?
    flow.failed? && job_event.include?('retry')
  end

  def failed?
    flow.failed? && job_event.include?('failed')
  end

  def stop?
    return false unless flow.finished? || failed?
    flow.mark_as_stopped
    log_failure if failed?
    true
  end

  def log_failure
    error = flow.jobs.find { |job| job.output_payload && job.output_payload[:event] == 'failed' }
    Rails.logger.error "ERROR in #{error.name}: #{error.output_payload[:message]}"
  end

  def job_event
    flow.jobs.collect do |job|
      next unless job.output_payload
      job.output_payload[:event]
    end.compact!
  end

  # Retry the job after 15 minutes
  def retry_later
    IngestWorkflowMonitorJob.set(wait: 15.minutes).perform_later(workflow_id: flow.id)
  end
end
