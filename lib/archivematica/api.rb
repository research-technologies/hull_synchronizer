module Archivematica
  class Api
    # Interfaces to Archivematica and Archivematica Storage Service APIs
    # All have a request method that returns a Faraday::Response object

    # Base api module
    module ApiBase
      attr_reader :params

      RESPONSES = {
        'Faraday::ClientError' => 418,
        'Faraday::ConnectionFailed' => 598,
        'Faraday::ResourceNotFound' => 404,
        'Faraday::ParsingError' => 418,
        'Faraday::TimeoutError' => 598,
        'Faraday::SSLError' => 418,
        'Faraday::RetryableResponse' => 500,
        'RuntimeError' => 418
      }.freeze

      def initialize(params: {})
        @params = params
      end

      def response_for(error:)
        response = Faraday::Response.new(
          status: RESPONSES[error.class.to_s],
          body: nil
        )
        response.env.response_headers = { warning: error.message }
        response
      end

      def connection_for(url:, auth:)
        Faraday.new(url: url) do |faraday|
          faraday.headers['Authorization'] = auth
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter do |client|
            client.read_timeout = 60
          end
        end
      end
    end

    # Creates connection to archivematica
    module ArchivematicaConnection
      def connection
        if ENV['AM_URL'].blank? || ENV['AM_USER'].blank? || ENV['AM_KEY'].blank?
          raise 'environment variables are not set'
        end
        auth = "ApiKey #{ENV['AM_USER']}:#{ENV['AM_KEY']}"
        connection_for(url: ENV['AM_URL'], auth: auth)
      end
    end

    # Creates connection to archivematica storage service
    module StorageServiceConnection
      def connection
        if ENV['SS_URL'].blank? || ENV['SS_USER'].blank? || ENV['SS_KEY'].blank?
          raise 'environment variables are not set'
        end
        auth = "ApiKey #{ENV['SS_USER']}:#{ENV['SS_KEY']}"
        connection_for(url: ENV['SS_URL'], auth: auth)
      end
    end

    # Interface for the start_transfer api call
    class StartTransfer
      include ApiBase
      include ArchivematicaConnection
      # POST /api/transfer/start_transfer/
      # params must contain [:name] and [:path]
      #   path is the transfer_source_path for the transfer in archivemaica
      # params may contain [:accession] and [:type]
      # @return [FaradayResponse] response
      def request
        raise 'name and path are required' if params[:name].blank? || params[:path].blank?
        raise 'AM_TS environment variable is not set' if ENV['AM_TS'].blank?
        type = params[:type] || 'unzipped bag'
        connection.post '/api/transfer/start_transfer/',
                        name: params[:name],
                        type: type, accession: params[:accession],
                        paths: [Base64.encode64("#{ENV['AM_TS']}:#{params[:path]}")]
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the transfer/approve api call
    class ApproveTransfer
      include ApiBase
      include ArchivematicaConnection
      # POST /api/transfer/approve/
      # params must contain [:directory]
      #   directory is the transfer directory name, not the full path
      # params may contain [:type]
      # @return [FaradayResponse] response
      def request
        raise 'directory is required' if params[:directory].blank?
        type = params[:type] || 'unzipped bag'
        connection.post '/api/transfer/approve',
                        directory: params[:directory],
                        type: type
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the transfer/unapproved api call
    class UnapprovedTransfers
      include ApiBase
      include ArchivematicaConnection
      # GET /api/transfer/unapproved
      # @return [FaradayResponse] response
      def request
        connection.get '/api/transfer/unapproved'
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the transfer/status api call
    class TransferStatus
      include ApiBase
      include ArchivematicaConnection
      # GET /transfer/status/<UUID>/
      # params must contain [:uuid] - transfer uuid
      # @return [FaradayResponse] response
      def request
        raise 'uuid is required' if params[:uuid].blank?
        connection.get "/api/transfer/status/#{params[:uuid]}/"
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the ingest/status api call
    class IngestStatus
      include ApiBase
      include ArchivematicaConnection
      # GET /ingest/status/<UUID>/
      # params must contain [:uuid] - sip/aip uuid
      # @return [FaradayResponse] response
      def request
        raise 'uuid is required' if params[:uuid].blank?
        connection.get "/api/ingest/status/#{params[:uuid]}/"
      rescue StandardError => e
        response_for(error: e)
      end
    end

    # Interface for the package details api call
    class PackageDetails
      include ApiBase
      include StorageServiceConnection
      # GET /api/v2/file/<UUID>/
      # @param uuid [String] sip/aip uuid
      # @return [FaradayResponse] response
      def request
        raise 'uuid is required' if params[:uuid].blank?
        connection.get "/api/v2/file/#{params[:uuid]}/"
      rescue StandardError => e
        response_for(error: e)
      end

      # Extract any DIP UUIDs from the AIP details (or vice versa)
      # @param related_packages [Hash]
      # @return [Array] dip uuids
      def dip_uuids(related_packages)
        return [] if related_packages.blank?
        related_packages.collect { |pack| pack.split('/').last }
      end
    end
  end
end
