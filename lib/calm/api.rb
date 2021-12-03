require 'savon'

module Calm
  class Api
    attr_reader :cookies

    def initialize
      raise('CALM_ENDPOINT environment variable is not set') if ENV['CALM_ENDPOINT'].blank?
      @client = Savon.client(
        wsdl: ENV['CALM_ENDPOINT'],
        log: true,
        logger: Rails.logger,
        log_level: :debug,
        convert_request_keys_to: :none,
        read_timeout: 600,
        write_timeout: 600)
      @cookies = []
    end

    def get_record_by_id(id)
      operation = :get_record_by_id
      params = {id: id}
      result, body = perform_operation(operation, params)
      return result, body
    end

    def get_record_by_field(field_name, value)
      operation = :get_record_by_field
      params = {
        fieldName: field_name,
        value: value,
      }
      result, body = perform_operation(operation, params)
      return result, body
    end

    def create_record(fields, type='Component')
      # params to include a hash of fields
      # example
      #   fields = {
      #     BarCode: '123242345',
      #     Level: 'Collection',
      #     Extent: '2.13 linear meters',
      #     Title: 'A new collection',
      #     Description: "Creating a new parent with reference Q DAB",
      #     RefNo: 'Q DAB'
      #   }
      #   type = 'Component'
      operation = :create_record
      params = {
        type: type,
        fields: { Field: fields.values, :attributes! => {Field: {name: fields.keys}}}
      }
      result, body = perform_operation(operation, params)
      return result, body
    end

    def create_child_record(fields, parentID, treeField='RefNo', type='Component', conform=true)
      # params to include parentID and a hash of fields
      # example
      #   fields = {
      #     BarCode: '12324234567458645',
      #     Extent: 'A few pages',
      #     Title: 'A child record to Q DAB',
      #     Date: '2018-10-10',
      #     Description: 'This is a child recordbeloging to the parent 2253ce08-7106-43ba-857f-eac0c86b0021',
      #     RefNo: 'Q DAB/1'
      #   }
      #   parentID = '2253ce08-7106-43ba-857f-eac0c86b0021'
      #   treeField = 'RefNo'
      #   type = 'Component'
      #   conform = true
      operation = :create_child_record

      params = {
        recordType: type,
        parentID: parentID,
        treeField: treeField,
        fields: { Field: fields.values, :attributes! => { Field: { name: fields.keys } } },
        conform: conform
      }
      result, child_id = perform_operation(operation, params)

      if result == true 
        # Record has been created we will now update it so that the ALtREFNo is the same as the RefNo
        u_result, body = get_record_by_id(child_id)
        if u_result == true && body.key?('RefNo')
          mods = {:AltRefNo => body['RefNo'][0].to_s}
          update_record(child_id,{},mods)
        end
      end
      return result, child_id
    end

    def update_record(recordID, add={}, modify={}, delete=[])
      operation = :update_record

      params = {
        id: recordID,
        fieldsToAdd: { Field: add.values, :attributes! => { Field: { name: add.keys } } },
        fieldsToModify: { Field: modify.values, :attributes! => { Field: { name: modify.keys } } },
        fieldsToDelete: delete,
      }
      result, body = perform_operation(operation, params)
    end

    def search(query)
      operation = :search
      params = {
        searchExpression: query
      }
      result, body = perform_operation(operation, params)
      return result, body
    end

    def get_search_result(from, count)
      #TODO: This doesn't seem to work
      operation = :overview
      params = {
        fields: { string: ['Title', 'RefNo']},
        from: from,
        count: count
      }
      result, body = perform_operation(operation, params)
      return result, body
    end

    private

    def perform_operation(operation, params)
      if @cookies.any?
        params[:cookies] = @cookies
      end
      begin
        response = @client.call(operation, message: params)
        parse_response(operation, response)
      rescue StandardError => e
        #"{e.message}\n#{e.backtrace}"
        return [false, e.message]
      end

    end

    def parse_response(operation, response)
      if response.soap_fault?
        return response.soap_fault?, response.fault
      elsif response.http_error?
        return response.http_error?, response.http_error
      else
        # save the session, if not already saved
        if response.http.cookies.any?
          @cookies = response.http.cookies
        end
        return response.success?, parse_response_by_operation(operation, response)
      end
    end

    def parse_response_by_operation(operation, response)
      case operation
      when :get_record_by_id
        element = 'Envelope/Body/GetRecordByIdResponse/GetRecordByIdResult/Record/Fields/Field'
        get_response_from_xml(response.to_xml, element)
      when :get_record_by_field
        element = 'Envelope/Body/GetRecordByFieldResponse/GetRecordByFieldResult/Record/Fields/Field'
        get_response_from_xml(response.to_xml, element)
      when :create_record
        response.body.dig(
          :create_record_response,
          :create_record_result
        )
      when :create_child_record
        response.body.dig(
          :create_child_record_response,
          :create_child_record_result
        )
      when :search
        response.body.dig(
          :search_response,
          :search_result,
          :search_summary
        )
      else
        response.body
      end
    end

    def get_response_from_xml(raw_xml, element)
      doc = Nokogiri::XML(raw_xml)
      doc.remove_namespaces!
      values = {}
      doc.search("./#{element}").each do |each_ele|
        field = each_ele.xpath('@name')
        new_vals = values.fetch(field.to_s, [])
        new_vals << each_ele.text.strip if each_ele.text && each_ele.text.strip
        values[field.to_s] = new_vals if new_vals.any?
      end
      values
    end

  end
end
