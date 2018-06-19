module Archivematica
  # call the start transfer archivematica api
  class StartTransferJob < BaseJob
    def perform(job_status_id:, name:, path:, type: nil, accession: nil)
      @job_status_id = job_status_id
      p = { name: name, path: path }
      p[:type] = type unless type.blank?
      p[:accession] = accession unless accession.blank?
      @response = Archivematica::Api::StartTransfer.new(params: p).request
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
      if body['message'] == 'Copy successful'
        job_status(code: 'success', message: message_text)
        next_job.perform_later(
          job_status_id: job_status_id,
          path: body['path'].split('/').last
        )
      else
        job_status(message: message_text)
      end
    end

    def next_job
      Archivematica::ApproveTransferJob
    end
  end
end
