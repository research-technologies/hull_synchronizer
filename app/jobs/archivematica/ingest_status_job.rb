module Archivematica
  # call the ingest status archivematica api
  class IngestStatusJob < BaseJob
    def perform(job_status_id:, uuid:)
      @job_status_id = job_status_id
      p = { uuid: uuid }
      @response = Archivematica::Api::IngestStatus.new(params: p).request
      @job_status_id = job_status_id
      act_on_status
    end

    private

      def act_on_status
        if status == 200
          act_on_ok(ingest_status: body['status'])
        else
          act_on_error
        end
      end

      def act_on_ok(ingest_status:)
        case ingest_status
        when 'COMPLETE'
          complete(ingest_status: ingest_status)
        when 'PROCESSING'
          update(ingest_status: ingest_status)
        when 'USER_INPUT'
          user_input(ingest_status: ingest_status)
        else
          job_status(message: ingest_status)
        end
      end

      def complete(ingest_status:)
        job_status(code: 'success', message: ingest_status)
        next_job.set(wait: 5.minutes).perform_later(
          job_status_id: job_status_id,
          uuid: body['uuid']
        )
      end

      def update(ingest_status:)
        job_status(code: 'retry', message: ingest_status)
        current_job.set(wait: 5.minutes).perform_later(
          job_status_id: job_status_id,
          uuid: body['uuid']
        )
      end

      def user_input(ingest_status:)
        # TODO: send an email
        job_status(code: 'retry', message: ingest_status)
        current_job.set(wait: 60.minutes).perform_later(
          job_status_id: job_status_id,
          uuid: body['uuid']
        )
      end

      def next_job
        Archivematica::PackageDetailsJob
      end
  end
end
