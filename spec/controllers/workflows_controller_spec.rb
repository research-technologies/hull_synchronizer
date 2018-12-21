require 'rails_helper'

RSpec.describe WorkflowsController, type: :controller do
  
  describe "GET #index" do
    it "assigns @client and @workflow" do
      get :index
      expect(assigns(:client)).to be_a(Gush::Client)
      expect(assigns(:workflows)).to be_a(Array)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template :index
    end
  end
end
