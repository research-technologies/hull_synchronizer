require "rails_helper"

RSpec.describe ReviewsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/reviews").to route_to("reviews#index")
    end

    it "routes to #new" do
      skip 'This route is disabled'
      expect(get: "/reviews/new").not_to be_routable
    end

    it "routes to #show" do
      expect(get: "/reviews/1").to route_to("reviews#show", id: "1")
    end

    it "routes to #edit" do
      skip 'This route is disabled'
      expect(get: "/reviews/1/edit").not_to be_routable
    end

    it "routes to #create" do
      skip 'This route is disabled'
      expect(post: "/reviews").not_to be_routable
    end

    it "routes to #update via PUT" do
      expect(put: "/reviews/1").not_to be_routable
    end

    it "routes to #update via PATCH" do
      expect(patch: "/reviews/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete: "/reviews/1").to route_to("reviews#destroy", id: "1")
    end

    it "routes to #retry_reviews" do
      expect(get: "/retry_review/1").to route_to("reviews#retry_review", id: "1")
    end
  end
end
