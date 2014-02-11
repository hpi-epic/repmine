require 'spec_helper'

describe "ontologies/show" do
  before(:each) do
    @ontology = assign(:ontology, stub_model(Ontology))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
