require 'rails_helper'

RSpec.describe "ingests/new", type: :view do
  before do
    assign(:ingest, Ingest.new)
  end

  it "renders new ingest form" do
    render

    assert_select "form[action=?][method=?]", ingests_path, "post" do
    end
  end
end
