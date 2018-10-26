  # BaseJob for all Archivematica and SWORD jobs.
  class BaseJob < Gush::Job
    require 'archivematica/api'
    require 'sword/api'
    attr_reader :response

    def perform
      raise NotImplementedError, 'Use one of the subclasses of BaseJob'
    end

    private

      delegate :status, to: :response

      # Return the response body
      # @return [Hash] the response body
      def body
        JSON.parse(response.body) unless response.body.nil?
      rescue JSON::ParserError
        ''
      end

      # If response code is 200 or 201, continue
      def act_on_status
        if status and status.between?(200,201) 
          act_on_ok
        else
          Rails.logger.error("Job failed with: #{message_text}")
          output(event: 'failed', message: message_text)
          fail!
        end
      end

      # Create a message for return with the job
      # @return [String] message
      def message_text
        if body.is_a?(Hash) && body.key?('message')
          body['message']
        else
          response.reason_phrase
        end
      end
  end
