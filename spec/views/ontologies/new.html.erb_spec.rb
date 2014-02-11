require 'spec_helper'

describe "ontologies/new" do
  before(:each) do
    assign(:ontology, stub_model(Ontology).as_new_record)
  end

  it "renders new ontology form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", ontologies_path, "post" do
    end
  end
end
