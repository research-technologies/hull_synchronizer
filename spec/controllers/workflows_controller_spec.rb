require 'rails_helper'

RSpec.describe WorkflowsController, type: :controller do
  
  describe "GET #index" do
    it "assigns @client and @workflow" do
      get :index
      expect(assigns(:client)).to be_a(Gush::Client)
      expect(assigns(:workflows)).to be_a(Array)
    end
    
    before(:each) do
    user = instance_double('user')
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

    it "renders the index template" do
      get :index
      expect(response).to render_template :index
    end
  end
end
