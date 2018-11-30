module Archivematica
  # Call the approve transfer archivematica api
  class ApproveTransferJob < BaseJob
    # Approve transfer
    #  sleep 10 seconds to allow for completion of StartTransfer
    # payloads.first[:output] [Hash] required params
    def perform
      sleep(10)
      @response = Archivematica::Api::ApproveTransfer.new(params: payloads.first[:output]).request
      act_on_status
    end

    private

      # If response message is success, return params for next job
      def act_on_ok
        if body['message'] == 'Approval successful.'
          output(
            event: 'success',
            message: message_text,
            uuid: body['uuid'],
            accession: payloads.first[:output][:accession]
          )
        else
          Rails.logger.error("Job failed with: #{message_text}")
          output(event: 'failed', message: message_text)
          fail!
        end
      end
  end
end
