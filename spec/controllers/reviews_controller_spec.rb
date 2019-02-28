require 'rails_helper'

RSpec.describe ReviewsController, type: :controller do
  
  let(:valid_attributes) { :id }

  let(:invalid_attributes) do
    skip("Add a hash of attributes invalid for your model")
  end
  
  let(:client) { Gush::Client.new }
  let(:review) { instance_double(ReviewWorkflow) }
  
  before(:each) do
    user = instance_double('user')
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "assigns @client and @reviews" do
      get :index
      expect(assigns(:client)).to be_a(Gush::Client)
      expect(assigns(:reviews)).to be_a(Array)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template :index
    end
  end

  describe "GET #show" do
    before do 
      allow(ReviewWorkflow).to receive(:find).and_return(review)
    end
    it "assigns the requested review to @review" do
      get :show, params: { id: '1234' }
      expect(assigns(:review)).to eq(review)
    end
    it "renders the #show view" do
      get :show, params: { id: '1234' }
      expect(response).to render_template :show
    end
  end

  describe "DELETE #destroy" do
    before do
      allow(Gush::Client).to receive(:new).and_return(client)
      allow(client).to receive(:find_workflow).with('1234').and_return(review)
      allow(client).to receive(:destroy_workflow).with(review)
      
    end
    it "destroys the requested review" do
      delete :destroy, params: { id: '1234' }
      expect(response).to redirect_to(:reviews)
    end
  end
  
  describe "GET #retry_review" do
    before do 
      allow(ReviewWorkflow).to receive(:find).and_return(review)
      allow(review).to receive(:continue)
      allow(review).to receive(:reload)
    end
    it "assigns the requested review to @review" do
      get :retry_review, params: { id: '1234' }
      expect(assigns(:review)).to eq(review)
    end
    it "renders the #show view" do
      get :retry_review, params: { id: '1234' }
      expect(response).to redirect_to(:review)
    end
  end
end
