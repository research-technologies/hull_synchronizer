module Archivematica
  # call the package details archivematica storage service api
  class PackageDetailsJob < BaseJob
    attr_reader :dip_uuid, :metadata

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
        add_metadata(metadata_hash: body)
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
        add_metadata(metadata_hash: dip_body)
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
      UnpackDipForDepositJob.perform_later(
        job_status_id: job_status_id,
        dip_location: metadata[:dip_current_full_path],
        metadata: metadata
      )
    end

    def next_job
      UnpackDipForDepositJob
    end

    def add_metadata(metadata_hash:)
      p_type = metadata_hash['package_type'].downcase if metadata_hash['package_type']
      metadata_hash.each_pair do |key, value|
        next if %w[package_type misc_attributes related_packages].include? key
        if key == 'origin_pipeline'
          @metadata[key.to_sym] = value
        else
          @metadata["#{p_type}_#{key}".to_sym] = value
        end
      end
    end
  end
end
