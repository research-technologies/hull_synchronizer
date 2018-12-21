require "rails_helper"

RSpec.describe WorkflowsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/workflows").to route_to("workflows#index")
    end

    it "routes to #new" do
      skip 'This route is disabled'
      expect(get: "/workflows/new").not_to be_routable
    end

    it "routes to #show" do
      expect(get: "/workflows/1").not_to be_routable
    end

    it "routes to #edit" do
      skip 'This route is disabled'
      expect(get: "/workflows/1/edit").not_to be_routable
    end

    it "routes to #create" do
      skip 'This route is disabled'
      expect(post: "/workflows").not_to be_routable
    end

    it "routes to #update via PUT" do
      expect(put: "/workflows/1").not_to be_routable
    end

    it "routes to #update via PATCH" do
      expect(patch: "/workflows/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete: "/workflows/1").not_to be_routable
    end
  end
end
