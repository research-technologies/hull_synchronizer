module Archivematica
  # call the start transfer archivematica api
  class StartTransferJob < BaseJob
    # Start transfer
    # payloads.first[:output] [Hash] required params
    # @todo params will be supplied by payloads.first[:output]
    def perform
      @response = Archivematica::Api::StartTransfer.new(params: params).request
      # @response = Archivematica::Api::StartTransfer.new(params: payloads.first[:output]).request
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
            type: params[:type]
          )
        else
          output(event: 'failed', message: message_text)
          fail!
        end
      end
  end
end
