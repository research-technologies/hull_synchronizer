module Sword
  class Api
    # Interfaces to a SWORD endpoint

    # Base api module
    module ApiBase
      attr_reader :params, :response, :connection

      RESPONSES = {
        "RuntimeError" => 418
      }.freeze

      def initialize(params: {})
        @params = params
        setup_connection(conn_for: self.class.to_s)
      end

      # @return [Faraday::Response] response object containing error info
      def response_for(error:)
        message = error.message || 'something went wrong'
        @response = Faraday::Response.new(
          status: RESPONSES[error.class.to_s],
          body: message
        )
        @response.env.reason_phrase = message
        response
      end

      def setup_connection(conn_for:)
        raise 'environment variables are not set' if ENV['SWORD_ENDPOINT'].blank?

        @connection = Faraday.new(url: ENV['SWORD_ENDPOINT'], request: { timeout: 4800 }) do |faraday|
          faraday.headers['Authorization'] = auth unless auth.nil?
          faraday.headers['Content-Type'] = 'application/xml' unless conn_for == 'Sword::Api::Work'
          faraday.adapter :net_http
          # @todo REMOVE ONCE SSL IN PLACE if Rails.env == 'development' && ENV['SWORD_ENDPOINT'].include?('https')
          faraday.ssl[:verify] = false
          faraday.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
#          Rails.logger.info("Faraday timeout is : #{connection.request.options.timeout}")
          # end
        end
      end

      def auth
        "Basic #{ENV['SWORD_USER']}:#{ENV['SWORD_PASSWORD']}" if ENV['SWORD_USER'] && ENV['SWORD_PASSWORD']
      end
    end

    # Interface for the start_transfer api call
    class ServiceDocument
      include Sword::Api::ApiBase
      # GET /sword/service_document
      # @return [FaradayResponse] response
      def request
        @response = connection.get '/sword/service_document'
        response
      rescue StandardError => e
        response_for(error: e)
      end

      # @return [Array] collection urls
      def collections
        return [] if response.status != 200
        Nokogiri::XML(response.body).remove_namespaces!.css('collection').map { |coll| coll.attributes['href'].value }
      end
    end

    class Collection
      include Sword::Api::ApiBase

      # GET /sword/collections/[collection_id]
      # @return [FaradayResponse] response
      def request
        @response = connection.get "/sword/collections/#{ENV.fetch('SWORD_COLLECTION', 'default')}"
        response
      rescue StandardError => e
        response_for(error: e)
      end

      # @return [Array] deposit urls
      def works
        return [] if response.status != 200
        Nokogiri::XML(response.body).remove_namespaces!.css('feed>link').map { |link| link.attributes['href'].value }
      end

      def file_sets
        return [] if response.status != 200
        Nokogiri::XML(response.body).remove_namespaces!.css('entry>link').map { |link| link.attributes['href'].value }
      end

      def content
        return [] if response.status != 200
        Nokogiri::XML(response.body).remove_namespaces!.css('entry>content').map { |link| link.attributes['href'].value }
      end
    end

    class Work
      include Sword::Api::ApiBase

      # rubocop:disable Metrics/AbcSize

      # POST /sword/collection/[collection_id]/works
      # params must contain [:file] hash with [:content_type] and [:path]
      # @return [FaradayResponse] response
      def request

        raise '[:file] hash with [:content_type] and [:path] is required' if file_hash?
        body = Faraday::UploadIO.new(params[:file][:path],params[:file][:content_type],params[:file][:path].split('/').last)
        @response = connection.post "/sword/collections/#{ENV.fetch('SWORD_COLLECTION', 'default')}/works" do |req|
          req.body = body
          if body.respond_to?(:length)
            req.headers['Content-Length'] = body.length.to_s
          elsif body.respond_to?(:stat)
            req.headers['Content-Length'] = body.stat.size.to_s
          end
          req.headers['Packaging'] = packaging
          req.headers['In-Progress'] = in_progress
          req.headers['On-Behalf-Of'] = params[:on_behalf_of] if params[:on_behalf_of]
          req.headers['Hyrax-Work-Model'] = params[:hyrax_work_model] if params[:hyrax_work_model]
          req.headers['Content-Disposition'] = "attachment; filename=#{params[:file][:path].split('/').last}"
          req.headers['Content-Type'] = params[:file][:content_type]
        end
        response
      rescue StandardError => e
        response_for(error: e)
      end
      # rubocop:enable Metrics/AbcSize

      def file_hash?
        params[:file].blank? || !params[:file].include?((:content_type || :path))
      end

      def packaging
        params[:packaging] ? params[:packaging] : 'application/atom+xml;type=entry'
      end

      def in_progress
        params[:in_progress] ? params[:in_progress] : 'false'
      end

      # @return [Hash] hash containing info on work and filesets
      def deposit
        return {} if response.status != 201
        {
          content: content,
          file_sets: file_sets
        }
      end

      def content
        Nokogiri::XML(response.body).remove_namespaces!.css('content').first.attributes['href'].value
      end

      def file_sets
        Nokogiri::XML(response.body).remove_namespaces!.css('link').map { |link| link.attributes['href'].value }
      end
    end
  end
end
