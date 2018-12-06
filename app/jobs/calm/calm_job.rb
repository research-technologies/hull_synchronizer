module Calm
  require 'calm'
  # CALM Create job
  class CalmJob < Gush::Job
    attr_accessor :calm_metadata, :fields, :calm_api, :response, :work_id

    SUPPORTED_FIELDS = [:accession_number,
                        :title,
                        :access_status,
                        :copyright,
                        :creator,
                        :date,
                        :description,
                        :keywords,
                        :language].freeze

    def perform
      @calm_metadata = payloads.first[:output][:works][params][:calm_metadata]
      @fields = {}
      @work_id = payloads.first[:output][:work_id]
      build_fields
      setup_calm
      @response = calm_api.create_child_record(fields, parent_id)
      act_on_status
    end

    private

      # Connect to CALM
      def setup_calm
        @calm_api = Calm::Api.new
      end

      def act_on_status
        if response.first == true
          act_on_ok
        else
          message_text = "Job failed with: #{response.last}"
          Rails.logger.error(message_text)
          output(event: 'failed', message: message_text)
          fail!
        end
      end

      def act_on_ok
        output(
          event: 'success',
          message: "#{response.last} successfully added to CALM",
          works: payloads.first[:output][:works]
        )
      end

      # Get the RecordId for the Collection with the RefNo
      #
      # @return [String] RecordID
      def parent_id
        parent = calm_api.get_record_by_field('RefNo', calm_metadata[:reference])
        return parent.last['RecordID'].join unless parent.first == false
      end

      # Build a hash of metadata to pass to CALM
      def build_fields
        SUPPORTED_FIELDS.each do |f|
          name = field_name[f]
          fields[name] = field_content(f, calm_metadata[f] || nil) unless name.nil?
          fields.compact!
        end
        # @todo replace with proper DAO field
        fields['Location'] = work_id
      end

      # Retrieve the CALM field name
      def field_name
        {
          accession_number: 'AccNo',
          title: 'Title',
          access_status: 'AccessStatus',
          copyright: 'Copyright',
          creator: 'CreatorName',
          date: 'Date',
          description: 'Description',
          user_description: 'Description',
          keywords: 'Keyword',
          language: 'Language',
          filename: 'Title'
        }
      end

      # Process the field content
      #   provide defaults for language and access_status
      #   use the filename if no title is supplied
      def field_content(field, value)
        case field
        when :description
          desc = value
          if calm_metadata[:user_description]
            desc += "\n" unless value.nil?
            desc += "User Description: #{value}"
          end
          desc
        when :language
          value.nil? ? 'English' : value
        when :access_status
          value.nil? ? 'closed' : value
        when :title
          value.nil? ? "File name: #{calm_metadata[:filename]}" : value
        else
          value
        end
      end
  end
end
