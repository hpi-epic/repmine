require 'spec_helper'

describe "ontologies/index" do
  before(:each) do
    assign(:ontologies, [
      stub_model(Ontology),
      stub_model(Ontology)
    ])
  end

  it "renders a list of ontologies" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
