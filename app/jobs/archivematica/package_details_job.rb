module Archivematica
  # call the package details archivematica storage service api
  class PackageDetailsJob < BaseJob
    attr_reader :metadata, :dip_uuid

    def perform(job_status_id:, uuid:)
      @job_status_id = job_status_id
      pd = Archivematica::Api::PackageDetails.new(params: { uuid: uuid })
      @response = pd.request
      @dip_uuid = pd.dip_uuids(body['related_packages']).first
      @metadata = {}
      act_on_status
    end

    private

    def act_on_status
      if status == 200
        act_on_ok
      else
        job_status(code: 'error', message: body['status'])
      end
    end

    def act_on_ok
      if body['status'] == 'UPLOADED'
        # TODO: metadata[:blah]
        # we're assuming just one DIP
        dip_response(
          dip_uuid: dip_uuid
        )
      else
        job_status(code: 'retry', message: body['status'])
        Archivematica::PackageDetailsJob.perform_later(
          job_status_id: job_status_id, uuid: body['uuid']
        )
      end
    end

    def dip_response(dip_uuid:)
      dip_r = Archivematica::Api::PackageDetails.new(
        params: { uuid: dip_uuid }
      ).request
      if dip_r.status == 200
        act_on_ok_dip(dip_r: dip_r)
      else
        act_on_error
      end
    end

    def act_on_ok_dip(dip_r:)
      dip_body = JSON.parse(dip_r.body)
      if dip_body['status'] == 'UPLOADED'
        metadata[:blah]
        start_deposits
      else
        job_status(code: 'retry', message: dip_body['status'])
        Archivematica::PackageDetailsJob.perform_later(
          job_status_id: job_status_id, uuid: body['uuid']
        )
      end
    end

    def start_deposits
      job_status(code: 'success', message: body['status'])
      # UnpackDipForDepositJob.perform_later
      #   (job_status_id: job_status_id, dip_location: xxx)
      # -> Sword::PrepareDepositJob.perform_later
      #   (job_status_id, metadata, [files], model)
      # ---> Sword::DepositJob.perform_later
      #   (job_status_id, deposit_bag_location)
    end
  end
end
