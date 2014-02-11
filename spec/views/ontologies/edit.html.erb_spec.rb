require 'spec_helper'

describe "ontologies/edit" do
  before(:each) do
    @ontology = assign(:ontology, stub_model(Ontology))
  end

  it "renders the edit ontology form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", ontology_path(@ontology), "post" do
    end
  end
end
