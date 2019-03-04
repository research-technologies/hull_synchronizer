require "savon/mock/spec_helper"
require 'json'
RSpec.describe Calm::Api do
  # include the helper module
  include Savon::SpecHelper
  
  ENV['CALM_ENDPOINT'] = 'http://www.calmhosting01.com/CalmAPI-HullUni/archive/catalogue.asmx?WSDL'
  # set Savon in and out of mock mode
  before(:all) do
    savon.mock!
    @calm_api = described_class.new
  end
  before do
    wsdl = 'http://www.calmhosting01.com/CalmAPI-HullUni/archive/catalogue.asmx?WSDL'
    fixture = File.read("spec/fixtures/files/calm/wsdl.xml")
    stub_request(:get, wsdl).to_return(status: 200, body: fixture)
  end
  after(:all) { savon.unmock! }

  describe "#get_record_by_id" do
    it "returns the record with given ID" do
      # parameters
      id = '2253ce08-7106-43ba-857f-eac0c86b0021'
      # set up an expectation
      message = { id: id }
      message[:cookies] = @calm_api.cookies if @calm_api.cookies.any?
      fixture = File.read("spec/fixtures/files/calm/get_record_by_id.xml")
      savon.expects(:get_record_by_id).with(message: message).returns(fixture)
      # call the service
      response, body = @calm_api.get_record_by_id(id)
      expect(response).to be true
      response_hash = JSON.parse(File.read("spec/fixtures/files/calm/get_record_by_id.json"))
      expect(body).to eq(response_hash)
    end
  end

  describe "#get_record_by_field" do
    it "returns the record matching the given field name and value" do
      # parameters
      field_name = 'RefNo'
      value = 'Q DAB'
      # set up an expectation
      message = {
        fieldName: field_name,
        value: value
      }
      message[:cookies] = @calm_api.cookies if @calm_api.cookies.any?
      fixture = File.read("spec/fixtures/files/calm/get_record_by_field.xml")
      savon.expects(:get_record_by_field).with(message: message).returns(fixture)
      # call the service
      response, body = @calm_api.get_record_by_field(field_name, value)
      expect(response).to be true
      response_hash = JSON.parse(File.read("spec/fixtures/files/calm/get_record_by_field.json"))
      expect(body).to eq(response_hash)
    end
  end

  describe "#create_record" do
    it "creates the record" do
      # parameters
      fields = {
        BarCode: '1232423467',
        Level: 'Collection',
        Extent: '2.13 linear meters',
        Title: 'A 2nd new collection',
        Description: "Creating a new parent with reference Q DAB",
        RefNo: 'Q DAB'
      }
      # set up an expectation
      message = {
        type: 'Component',
        fields: { Field: fields.values, attributes!: { Field: { 'name' => fields.keys } } }
      }
      message[:cookies] = @calm_api.cookies if @calm_api.cookies.any?
      fixture = File.read("spec/fixtures/files/calm/create_record.xml")
      savon.expects(:create_record).with(message: :any).returns(fixture)
      # call the service
      response, body = @calm_api.create_record(fields)
      expect(response).to be true
      expect(body).to eq('2253ce08-7106-43ba-857f-eac0c86b0021')
    end
  end

  describe "#create_child_record" do
    it "creates the child record" do
      # parameters
      fields = {
        BarCode: '12324234567458645',
        Extent: 'A few pages',
        Title: 'A child record to Q DAB',
        Date: '2018-10-10',
        Description: 'This is a child recordbeloging to the parent 2253ce08-7106-43ba-857f-eac0c86b0021',
        RefNo: 'Q DAB/1'
      }
      parentID = '2253ce08-7106-43ba-857f-eac0c86b0021'
      # set up an expectation
      type = 'Component'
      treeField = 'RefNo'
      conform = true
      message = {
        recordType: type,
        parentID: parentID,
        treeField: treeField,
        fields: { Field: fields.values, attributes!: { Field: { name: fields.keys } } },
        conform: conform
      }
      message[:cookies] = @calm_api.cookies if @calm_api.cookies.any?
      fixture = File.read("spec/fixtures/files/calm/create_child_record.xml")
      savon.expects(:create_child_record).with(message: message).returns(fixture)
      # call the service
      response, body = @calm_api.create_child_record(fields, parentID)
      expect(response).to be true
      expect(body).to eq('8609bb23-f7cd-4a3d-94d5-b6c280a160ee')
    end
  end

  describe "#search" do
    it "searches for the record(s)" do
      # parameters
      query = 'RefNo=Q DAB'
      # set up an expectation
      message = {
        searchExpression: query
      }
      message[:cookies] = @calm_api.cookies if @calm_api.cookies.any?
      fixture = File.read("spec/fixtures/files/calm/search.xml")
      savon.expects(:search).with(message: message).returns(fixture)
      # call the service
      response, body = @calm_api.search(query)
      expect(response).to be true
      response_hash = {
        database: 'Catalog',
        search: 'RefNo=Q DAB',
        count: '114'
      }
      expect(body).to eq(response_hash)
    end
  end
end
