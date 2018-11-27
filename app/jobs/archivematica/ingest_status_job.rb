module Archivematica
  # call the ingest status archivematica api
  class IngestStatusJob < BaseJob
    attr_accessor :ingest_status

    # Get ingest status
    # payloads.first[:output] [Hash] required params
    def perform
      @response = Archivematica::Api::IngestStatus.new(params: payloads.first[:output]).request
      @ingest_status = body['status'] if body['status']
      act_on_status
    end

    private

      # If response message is COMPLETE, return params for next job
      def act_on_ok
        case ingest_status
        when 'COMPLETE'
          output(event: 'success', message: message_text, uuid: body['uuid'])
        when 'PROCESSING'
          output(event: 'retry', message: message_text)
          Rails.logger.error("Job was sent for a retry with: #{message_text}")
          fail!
        when 'USER_INPUT'
          # @todo send email
          Rails.logger.error("Job was sent for a retry with: #{message_text}")
          output(event: 'retry', message: message_text)
          fail!
        else
          Rails.logger.error("Job failed with: #{message_text}")
          output(event: 'failed', message: message_text)
          fail!
        end
      end
  end
end
