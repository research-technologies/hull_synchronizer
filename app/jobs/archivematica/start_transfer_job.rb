module Archivematica
  # call the start transfer archivematica api
  class StartTransferJob < BaseJob
    attr_reader :transfer_type
    def perform(job_status_id:, name:, path:, type: nil, accession: nil)
      @job_status_id = job_status_id
      p = { name: name, path: path }
      @transfer_type = type unless type.blank?
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
        if body['message'] == 'Copy successful.'
          job_status(code: 'success', message: message_text)
          next_job.set(wait: 30.seconds).perform_later(
            job_status_id: job_status_id,
            directory: body['path'].split('/').last,
            type: transfer_type
          )
        else
          # TODO: might want to call unapproved transfers here? or do that with a nightly job?
          job_status(message: message_text)
        end
      end

      def next_job
        Archivematica::ApproveTransferJob
      end
  end
end
