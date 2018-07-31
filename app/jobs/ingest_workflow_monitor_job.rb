class IngestWorkflowMonitorJob < ActiveJob::Base
  queue_as :workflow_monitor
  attr_accessor :flow

  # Monitors the given Gush worklfow
  #   Gush jobs can have a status of running, complete or failed
  #   If the status is complete, we do no further processing.

  #   If the status is failed:
  #     failed jobs can be retried with the workflows's continue method
  #     but we want to know whether the failed status is something that
  #     can be recovered from (eg. the transfer isn't yet complete in
  #     Archivematica) or is a genuine failure (eg. a 500 error from Archivematica)
  #   The solution implemented is to set an event parameter in the output payload of each job:
  #     'failed' or 'retry'.
  #   If the event is retry, a new monitoring job is scheduled to run in 15 minutes.
  #   If event is failed, we mark the workflow as stopped and schedule no new jobs.

  def perform(workflow_id)
    @flow = IngestWorkflow.find(workflow_id)
    return if done?
    continue if retry?
    retry_later if retry?
  end

  # Continue a failed transfer
  #   give the continue 5 seconds
  #   then reload the stale flow object
  def continue
    flow.continue
    sleep(5)
    flow.reload
  end

  def retry?
    flow.failed? && job_event.include?('retry')
  end

  def failed?
    flow.failed? && job_event.include?('failed')
    flow.mark_as_stopped
  end

  def done?
    return false unless flow.finished? || failed?
    log_failure if failed?
    true
  end

  def log_failure
    flow.mark_as_stopped
    error = flow.jobs.find { |job| job.output_payload && job.output_payload[:event] == 'failed' }
    Rails.logger.error "ERROR in #{error.name}: #{error.output_payload[:message]}"
  end

  # @return [Array] list of event parameters from the payload
  def job_event
    flow.jobs.collect do |job|
      next unless job.output_payload
      job.output_payload[:event]
    end.compact!
  end

  # Schedule a new job to start after 15 minutes
  #  @todo consider whether we should limit the number of retries
  #    if so, this method could raise an error and use Sidekiq's retry functionality instead
  def retry_later
    IngestWorkflowMonitorJob.set(wait: 15.minutes).perform_later(flow.id)
  end
end
