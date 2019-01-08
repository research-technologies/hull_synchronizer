require "rails_helper"

RSpec.describe IngestsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/ingests").to route_to("ingests#index")
    end

    it "routes to #new" do
      skip 'This route is disabled'
      expect(get: "/ingests/new").not_to be_routable
    end

    it "routes to #show" do
      expect(get: "/ingests/1").to route_to("ingests#show", id: "1")
    end

    it "routes to #edit" do
      skip 'This route is disabled'
      expect(get: "/ingests/1/edit").not_to be_routable
    end

    it "routes to #create" do
      skip 'This route is disabled'
      expect(post: "/ingests").not_to be_routable
    end

    it "routes to #update via PUT" do
      expect(put: "/ingests/1").not_to be_routable
    end

    it "routes to #update via PATCH" do
      expect(patch: "/ingests/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete: "/ingests/1").to route_to("ingests#destroy", id: "1")
    end

    it "routes to #retry_ingests" do
      expect(get: "/retry_ingest/1").to route_to("ingests#retry_ingest", id: "1")
    end
  end
end
