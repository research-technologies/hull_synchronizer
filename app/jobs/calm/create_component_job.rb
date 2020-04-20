module Calm
  require 'calm'
  # CALM Create job
  class CreateComponentJob < BaseJob
    attr_accessor :calm_metadata, :calm_api, :response, :work_id

    SUPPORTED_FIELDS = [:accession_number,
                        :title,
                        :access_status,
                        :copyright,
                        :creator,
                        :date,
                        :description,
                        :keywords,
                        :language,
                        :level].freeze

    def perform
      @calm_metadata = params[:calm_metadata]
      @work_id = params[:work_id]
      setup_calm
      @response = calm_api.create_child_record(fields, parent_id)
      act_on_status
    end

    # Build a hash of metadata to pass to CALM
    def fields
      fields = {}
      SUPPORTED_FIELDS.each do |f|
        name = field_name[f]
        fields[name] = field_content(f, calm_metadata[f] || nil) unless name.nil?
        fields.compact!
      end
      fields['URL'] = work_id
      fields['catalogueStatus'] = "Catalogued"
      fields
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
          {
            event: 'failed',
            message: message_text
          }
        end
      end

      def act_on_ok
        {
          event: 'success',
          message: "#{response.last} successfully added to CALM"
        }
      end

      # Get the RecordId for the Collection with the RefNo
      #
      # @return [String] RecordID
      def parent_id
        parent = calm_api.get_record_by_field('RefNo', calm_metadata[:reference])
        return parent.last['RecordID'].join unless parent.first == false
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
          filename: 'Title',
          level: 'Level'
        }
      end

      # Process the field content
      #   provide defaults for language and access_status
      #   use the filename if no title is supplied
      def field_content(field, value)
        case field
        when :description
          description(value)
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

      def description(value)
        desc = value
        if calm_metadata[:user_description]
          desc += "\n" unless value.nil?
          desc += "User Description: #{calm_metadata[:user_description]}"
        end
        desc
      end
  end
end
