module Archivematica
  # call the package details archivematica storage service api
  class PackageDetailsJob < BaseJob
    attr_reader :dip_uuid, :metadata

    # Get package details for both AIP and DIP
    # payloads.first[:output] [Hash] required params
    def perform
      pd = Archivematica::Api::PackageDetails.new(params: payloads.first[:output])
      @response = pd.request
      @dip_uuid = pd.dip_uuids(body['related_packages']).first
      @metadata = {}
      act_on_status
    end

    private

      # If response message for AIP is success, get DIP
      def act_on_ok
        if body['status'] == 'UPLOADED'
          add_metadata(metadata_hash: body)
          dip_response
        else
          output(event: 'retry', message: message_text)
          fail!
        end
      end

      # Get package details for DIP
      # @param dip_uuid [String] DIP UUID
      def dip_response
        dip_r = Archivematica::Api::PackageDetails.new(
          params: { uuid: dip_uuid }
        ).request
        if dip_r.status == 200
          act_on_ok_dip(dip_r: dip_r)
        else
          # TODO define act_on_error(!)
          act_on_error
        end
      end

      # If response message is success, return params for next job
      # @param dip_r [FaradayResponse] response for DIP package details
      def act_on_ok_dip(dip_r:)
        dip_body = JSON.parse(dip_r.body)
        if dip_body['status'] == 'UPLOADED'
          add_metadata(metadata_hash: dip_body)
          output(
            event: 'success', message: message_text,
            dip_location: metadata[:dip_current_full_path],
            package_metadata: metadata
          )
        else
          Rails.logger.error("Job was sent for a retry with: #{message_text}")
          output(event: 'retry', message: message_text)
          fail!
        end
      end

      # Build the metadata hash
      def add_metadata(metadata_hash:)
        p_type = metadata_hash['package_type'].downcase if metadata_hash['package_type']
        metadata_hash.each_pair do |key, value|
          next if %w[package_type misc_attributes related_packages].include? key
          if key == 'origin_pipeline'
            metadata[key.to_sym] = value
          else
            metadata["#{p_type}_#{key}".to_sym] = value
          end
        end
        metadata[:accession] = payloads.first[:output][:accession]
      end
  end
end
