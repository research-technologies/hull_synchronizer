module Archivematica
  # BaseJob for all Archivematica jobs.
  class BaseJob < ActiveJob::Base
    require 'archivematica/api'
    queue_as :archivematica
    attr_reader :response, :job_status_id

    def perform
      raise NotImplementedError, 'Use one of the subclasses of BaseJob'
    end

    private

    delegate :status, to: :response

    def body
      JSON.parse(response.body)
    end

    # Handle http response codes other 200
    # Reschedule x retries for 500 series errors
    def act_on_error
      if (400..499).cover? status
        job_status(message: message_text)
      elsif (500..599).cover? status
        # reschedule x retries
        job_status(code: 'retry', message: message_text)
      else
        job_status(message: message_text)
      end
    end

    # Call the job status service
    def job_status(code: 'error', message:)
      JobStatusService.new(
        job_status_id: job_status_id,
        status: code,
        message: "#{status}: #{message}",
        job: job_id
      )
    end

    def message_text
      if response.body.blank? || body['message'].blank?
        response.headers[:warning]
      else
        body['message']
      end
    end
  end
end
