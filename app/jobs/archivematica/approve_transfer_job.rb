module Archivematica
  # Call the approve transfer archivematica api
  class ApproveTransferJob < BaseJob
    def perform(job_status_id:, directory:, type: nil)
      @job_status_id = job_status_id
      p = { directory: directory }
      params[:type] = type unless type.blank?
      @response = Archivematica::Api::ApproveTransfer.new(params: p).request
      act_on_status
    end

    private

    def act_on_status
      if status == 200
        act_on_ok
      else
        act_on_error
      end
    end

    def act_on_ok
      if body['message'] == 'Approval successful.'
        job_status(
          code: 'success', message: body['message']
        )
        next_job.set(wait: 5.minutes).perform_later(
          job_status_id: job_status_id, uuid: body['uuid']
        )
      else
        job_status
      end
    end

    def next_job
      Archivematica::TransferStatusJob
    end
  end
end
