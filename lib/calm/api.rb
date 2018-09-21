require 'savon'

module Calm
  class Api
    def initialize
      @client = Savon.client(wsdl: 'http://www.calmhosting01.com/CalmAPI-HullUni/archive/catalogue.asmx?WSDL')
      @cookies = nil
    end

    def get_record_by_id(id)
      operation = :get_record_by_id
      params = {id: id}
      result, body = perform_operation(operation, params)
      return result, body
    end

    def create_record(type, fields)
      # params to include type and a list of fields
      # example
      #   fields = %w(BarCode Level Extent Title Date Description)
      #   type = 'Component'
      operation = :create_record
      params = {
        type: type,
        fields: fields.map{ |f| {field: {name: f}}}
      }
      result, body = perform_operation(operation, params)
      return result, body
    end

    def create_child_record(type, fields, parentID, treeField, conform)
      # params to include type and a list of fields
      # example
      #   fields = %w(BarCode Level Extent Title Date Description)
      #   recordType = type
      #   parentID = parentID
      #   treeField = 'ID'
      #   conform = boolean
      operation = :create_child_record
      params = {
        record_type: type,
        parentID: parentID,
        tree_field: treeField,
        fields: fields.map{ |f| {field: {name: f}}},
        conform: conform
      }
      perform_operation(operation, params)
    end

    private

    def perform_operation(operation, params)
      if @cookies
        @params[:cookies] = @cookies
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
        unless @cookies
          @cookies = response.http.cookies
        end
        return [response.success?, parse_response_hash(operation, response.body)]
      end
    end

    def parse_response_hash(operation, response_hash)
      case operation
      when :get_record_by_id
        response_hash.dig(
          :get_record_by_id_response,
          :get_record_by_id_result,
          :record,
          :fields,
          :field
        )
      when :create_record
        response_hash.dig(
          :create_record_response,
          :create_record_result
        )
      when :create_child_record
        response_hash.dig(
          :create_child_record_response,
          :create_child_record_result
        )
      else
        response_hash
      end
    end

  end
end
