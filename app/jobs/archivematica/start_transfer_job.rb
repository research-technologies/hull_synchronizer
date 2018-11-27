module Archivematica
  # call the start transfer archivematica api
  class StartTransferJob < BaseJob
    # Start transfer
    # payloads.first[:output] [Hash] required params
    def perform
      @response = Archivematica::Api::StartTransfer.new(params: payloads.first[:output]).request
      act_on_status
    end

    private

      # If response message is success, return params for next job
      def act_on_ok
        if body['message'] == 'Copy successful.'
          output(
            event: 'success',
            message: message_text,
            directory: body['path'].split('/').last,
            type: payloads.first[:output][:type],
            accession: payloads.first[:output][:accession]
          )
        else
          Rails.logger.error("Job was failed with: #{message_text}")
          output(event: 'failed', message: message_text)
          fail!
        end
      end
  end
end
