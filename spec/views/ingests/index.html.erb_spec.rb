require 'rails_helper'

RSpec.describe "ingests/index", type: :view do
  before do
    assign(:ingests, [
             Ingest.create!,
             Ingest.create!
           ])
  end

  it "renders a list of ingests" do
    render
  end
end
