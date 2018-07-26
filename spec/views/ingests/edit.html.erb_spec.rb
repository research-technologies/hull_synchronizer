require 'rails_helper'

RSpec.describe "ingests/edit", type: :view do
  before do
    @ingest = assign(:ingest, Ingest.create!)
  end

  it "renders the edit ingest form" do
    render

    assert_select "form[action=?][method=?]", ingest_path(@ingest), "post" do
    end
  end
end
