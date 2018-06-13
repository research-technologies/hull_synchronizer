module Archivematica
  # call the transfer status archivematica api
  class TransferStatusJob < BaseJob
    def perform(job_status_id:, uuid:)
      @job_status_id = job_status_id
      @response = Archivematica::Api::TransferStatus.new(
        params: { uuid: uuid }
      ).request
      act_on_status
    end

    private

    def act_on_status
      if status == 200
        act_on_ok(transfer_status: body['status'])
      else
        act_on_error
      end
    end

    def act_on_ok(transfer_status:)
      case transfer_status
      when 'COMPLETE'
        complete(transfer_status: transfer_status)
      when 'PROCESSING'
        update(transfer_status: transfer_status)
      when 'USER_INPUT'
        user_input(transfer_status: transfer_status)
      else
        job_status(message: transfer_status)
      end
    end

    def complete(transfer_status:)
      job_status(code: 'success', message: transfer_status)
      Archivematica::IngestStatusJob.set(wait: 5.minutes).perform_later(
        job_status_id: job_status_id,
        uuid: transfer_status
      )
    end

    def update(transfer_status:)
      job_status(code: 'retry', message: transfer_status)
      Archivematica::TransferStatusJob.set(wait: 5.minutes).perform_later(
        job_status_id: job_status_id,
        uuid: transfer_status
      )
    end

    def user_input(transfer_status:)
      # TODO: send an email
      job_status(code: 'retry', message: transfer_status)
      Archivematica::TransferStatusJob.set(wait: 1.days).perform_later(
        job_status_id: job_status_id,
        uuid: transfer_status
      )
    end
  end
end
