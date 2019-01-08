require "rails_helper"

RSpec.describe TransfersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/transfers").to route_to("transfers#index")
    end

    it "routes to #new" do
      skip 'This route is disabled'
      expect(get: "/transfers/new").not_to be_routable
    end

    it "routes to #show" do
      expect(get: "/transfers/1").to route_to("transfers#show", id: "1")
    end

    it "routes to #edit" do
      skip 'This route is disabled'
      expect(get: "/transfers/1/edit").not_to be_routable
    end

    it "routes to #create" do
      skip 'This route is disabled'
      expect(post: "/transfers").not_to be_routable
    end

    it "routes to #update via PUT" do
      expect(put: "/transfers/1").not_to be_routable
    end

    it "routes to #update via PATCH" do
      expect(patch: "/transfers/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete: "/transfers/1").to route_to("transfers#destroy", id: "1")
    end

    it "routes to #retry_transfers" do
      expect(get: "/retry_transfer/1").to route_to("transfers#retry_transfer", id: "1")
    end
  end
end
