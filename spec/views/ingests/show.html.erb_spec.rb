require 'rails_helper'

RSpec.describe "ingests/show", type: :view do
  before do
    @ingest = assign(:ingest, Ingest.create!)
  end

  it "renders attributes in <p>" do
    render
  end
end
