require 'rails_helper'

RSpec.describe TransfersController, type: :controller do
  
  let(:valid_attributes) { :id }

  let(:invalid_attributes) do
    skip("Add a hash of attributes invalid for your model")
  end
  
  let(:client) { Gush::Client.new }
  let(:transfer) { instance_double(TransferWorkflow) }
  
  before(:each) do
    user = instance_double('user')
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "assigns @client and @transfers" do
      get :index
      expect(assigns(:client)).to be_a(Gush::Client)
      expect(assigns(:transfers)).to be_a(Array)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template :index
    end
  end

  describe "GET #show" do
    before do 
      allow(TransferWorkflow).to receive(:find).and_return(transfer)
    end
    it "assigns the requested transfer to @transfer" do
      get :show, params: { id: '1234' }
      expect(assigns(:transfer)).to eq(transfer)
    end
    it "renders the #show view" do
      get :show, params: { id: '1234' }
      expect(response).to render_template :show
    end
  end

  describe "DELETE #destroy" do
    before do
      allow(Gush::Client).to receive(:new).and_return(client)
      allow(client).to receive(:find_workflow).with('1234').and_return(transfer)
      allow(client).to receive(:destroy_workflow).with(transfer)
      
    end
    it "destroys the requested transfer" do
      delete :destroy, params: { id: '1234' }
      expect(response).to redirect_to(:transfers)
    end
  end
  
  describe "GET #retry_transfer" do
    before do 
      allow(TransferWorkflow).to receive(:find).and_return(transfer)
      allow(transfer).to receive(:continue)
      allow(transfer).to receive(:reload)
    end
    it "assigns the requested transfer to @transfer" do
      get :retry_transfer, params: { id: '1234' }
      expect(assigns(:transfer)).to eq(transfer)
    end
    it "renders the #show view" do
      get :retry_transfer, params: { id: '1234' }
      expect(response).to redirect_to(:transfer)
    end
  end
end
