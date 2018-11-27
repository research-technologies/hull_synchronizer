class TransferWorkflowMonitorJob < ActiveJob::Base
  queue_as :workflow_monitor
  attr_accessor :flow, :params
  # Params contain item_name, item_id, item_list and source_dir

  # Monitors the given Gush worklfow
  #   Gush jobs can have a status of running, complete or failed
  #   If the status is complete, we do no further processing.

  #   If the status is failed:
  #     failed jobs can be retried with the workflows's continue method
  #   The solution implemented is to set an event parameter in the output payload of each job to 'retry'.
  #   If the event is retry, and the workflow started less then 24 hours ago
  #     the failed downloads are retried
  #     a new monitoring job is scheduled to run in 15 minutes.
  #   If the event is retry, and the workflow started more then 24 hours ago
  #     we mark the workflow as having stopped and schedule no more jobs.

  def perform(params)
    @params = params
    @flow = TransferWorkflow.find(params[:workflow_id])
    inform_user if done?
    next_workflow if flow.finished?
    continue if retry?
    retry_later if retry? or flow.running?
  end

  def next_workflow
    # start next workflow
    next_flow = ReviewWorkflow.create(params)
    next_flow.start!
  end

  def inform_user
    # params need to cointain item_id, item_name, status, message, unlink
    u_params = {item_id: params[:item_id], item_name: params[:item_name]}
    if flow.finished?
      u_params[:status] = 'revewing'
      u_params[:unlink] = false # do not remove collaborator link
      u_params[:message] = 'Starting review of metadata and associated files'
    elsif failed?
      u_params[:status] = 'transfering_failed'
      u_params[:unlink] = true # remove collaborator link
      u_params[:message] = log_failure
    end
    Box::InformUserJob.perform_later(u_params)
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
    flow.failed? && job_event.include?('retry') && (flow_start > 1.day.ago.to_i)
  end

  def failed?
    flow.failed? && job_event.include?('retry') && (flow_start < 1.day.ago.to_i)
  end

  def done?
    flow.finished? || failed?
  end

  def log_failure
    flow.mark_as_stopped
    errored_jobs = flow.jobs.collect do |job|
      next unless job.failed?
      Array(job.output_payload[:message]).join('\n')
    end
    errored_jobs
  end

  # @return [Array] list of event parameters from the payload
  def job_event
    flow.jobs.collect do |job|
      next unless job.output_payload
      job.output_payload[:event]
    end.compact!
  end

  def flow_start
    first_job = flow.jobs.min_by{ |n| n.started_at || Time.now.to_i }
    first_job.started_at
  end

  # Schedule a new job to start after 15 minutes
  #  @todo consider whether we should limit the number of retries
  #    if so, this method could raise an error and use Sidekiq's retry functionality instead
  def retry_later
    # sleep(60)
    # TransferWorkflowMonitorJob.perform_now(params)
    TransferWorkflowMonitorJob.set(wait: 1.minutes).perform_later(params)
  end
end
