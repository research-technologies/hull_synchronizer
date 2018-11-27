module Archivematica
  # call the transfer status archivematica api
  class TransferStatusJob < BaseJob
    attr_accessor :transfer_status

    # Get transfer status
    # payloads.first[:output] [Hash] required params
    def perform
      @response = Archivematica::Api::TransferStatus.new(
        params: payloads.first[:output]
      ).request
      @transfer_status = body['status'] if body['status']
      act_on_status
    end

    private

      # If response message is COMPLETE, return params for next job
      def act_on_ok
        case transfer_status
        when 'COMPLETE'
          output(
            event: 'success',
            message: message_text,
            uuid: body['sip_uuid'],
            accession: payloads.first[:output][:accession]
          )
        when 'PROCESSING'
          output(event: 'retry', message: message_text)
          fail!
        when 'USER_INPUT'
          # @todo send email
          output(event: 'retry', message: message_text)
          fail!
        else
          output(event: 'failed', message: message_text)
          fail!
        end
      end
  end
end
