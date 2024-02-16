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

  def perform(workflow_id, params)
    @flow = IngestWorkflow.find(workflow_id)
    @params = params
    return if done?
    continue if retry?
    retry_later if retry? or flow.running?
  end

  # Continue a failed transfer
  #   give the continue 5 seconds
  #   then reload the stale flow object
  def continue
    flow.continue
    sleep(5)
    @flow = flow.reload
  end

  def retry?
    flow.failed? && job_event.include?('retry')
  end

  def failed?
    flow.failed? && job_event.include?('failed')

  end

  def done?
    if flow.finished?
      inform_user
      return true
    end
    if failed?
      log_failure
      inform_user
      true
    else
      false
    end
  end

  def log_failure
    errored_job = flow.jobs.find { |job| job.output_payload && job.output_payload[:event] == 'failed' }
    Rails.logger.error "ERROR in #{errored_job.name}: #{errored_job.output_payload[:message]}"
    flow.mark_as_stopped
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
    IngestWorkflowMonitorJob.set(wait: 15.minutes).perform_later(flow.id, @params)
  end

  def inform_user
    # params need to cointain item_id, item_name, status, message, unlink
    u_params = {
      item_id: @params[:item_id],
      item_name: @params[:item_name],
      unlink: true # remove collaborator link
    }
    if flow.finished?
      u_params[:status] = 'Done - ingest successful'
      u_params[:message] = "The package has been ingested successfully.\nDuring ingest the following steps are performed\n
      1. Transfer a package through archivematica \n
      2. Create a digital archival object in Hyrax \n
      3. Create digital objects in Hyrax \n
      4. Create entries in CALM\n
      Details of the job can be viewed at #{ENV['SERVER_URL']}/ingests/#{flow.id}"
    elsif failed?
      u_params[:status] = 'Done - ingest failed'
      u_params[:message] = "There was an error when ingesting the package.\nDuring ingest the following steps are performed\n
      1. Transfer a package through archivematica \n
      2. Create a digital archival object in Hyrax \n
      3. Create digital objects in Hyrax \n
      4. Create entries in CALM\n
      Details of the job can be viewed at #{ENV['SERVER_URL']}/ingests/#{flow.id}"
    end
    #Box::InformUserJob.perform_later(u_params)
  end
end
