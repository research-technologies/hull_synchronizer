require 'rails_helper'

RSpec.describe IngestsController, type: :controller do
  
  let(:valid_attributes) { :id }

  let(:invalid_attributes) do
    skip("Add a hash of attributes invalid for your model")
  end
  
  let(:client) { Gush::Client.new }
  let(:ingest) { instance_double(IngestWorkflow) }
  
  before(:each) do
    user = instance_double('user')
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "assigns @client and @ingests" do
      get :index
      expect(assigns(:client)).to be_a(Gush::Client)
      expect(assigns(:ingests)).to be_a(Array)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template :index
    end
  end

  describe "GET #show" do
    before do 
      allow(IngestWorkflow).to receive(:find).and_return(ingest)
    end
    it "assigns the requested ingest to @ingest" do
      get :show, params: { id: '1234' }
      expect(assigns(:ingest)).to eq(ingest)
    end
    it "renders the #show view" do
      get :show, params: { id: '1234' }
      expect(response).to render_template :show
    end
  end

  describe "DELETE #destroy" do
    before do
      allow(Gush::Client).to receive(:new).and_return(client)
      allow(client).to receive(:find_workflow).with('1234').and_return(ingest)
      allow(client).to receive(:destroy_workflow).with(ingest)
      
    end
    it "destroys the requested ingest" do
      delete :destroy, params: { id: '1234' }
      expect(response).to redirect_to(:ingests)
    end
  end
  
  describe "GET #retry_ingest" do
    before do 
      allow(IngestWorkflow).to receive(:find).and_return(ingest)
      allow(ingest).to receive(:continue)
      allow(ingest).to receive(:reload)
    end
    it "assigns the requested ingest to @ingest" do
      get :retry_ingest, params: { id: '1234' }
      expect(assigns(:ingest)).to eq(ingest)
    end
    it "renders the #show view" do
      get :retry_ingest, params: { id: '1234' }
      expect(response).to redirect_to(:ingest)
    end
  end
end
