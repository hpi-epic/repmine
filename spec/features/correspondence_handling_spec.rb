require 'rails_helper'

describe "Selecting Correspondences", :type => :feature do

  it "should redirect users to a correspondence selection containing all of their possible options" do
    create_conflict()
    visit(patterns_path)
    select(@onto.short_name, :from => "ontology_ids")
    find(:css, "#patterns_[value='#{@pattern.id}']").set(true)
    find(:xpath, "//button[contains(@name, 'translate')]").click()
    expect(TranslationPattern.count).to eq(1)
    expect(current_path).to eq(pattern_correspondence_selection_path(TranslationPattern.first))
    expect(page).to have_xpath("//input[@type='checkbox'][@value='#{@c1.id}']")
    expect(page).to have_xpath("//input[@type='checkbox'][@value='#{@c2.id}']")
    find(:xpath, "//input[@type='checkbox'][@value='#{@c2.id}']").set(true)
    click_button("Prepare!")
    expect(current_path).to eq(pattern_translate_path(TranslationPattern.first))
  end

  def create_conflict()
    @pattern = FactoryGirl.create(:pattern)
    o_in = @pattern.ontologies.first
    @onto = FactoryGirl.create(:ontology)
    @c1 = FactoryGirl.create(:simple_correspondence, onto1: o_in, entity1: @pattern.nodes.first.rdf_type, onto2: @onto)
    @c2 = FactoryGirl.create(:hardway_complex, onto1: o_in, onto2: @onto)
    om = OntologyMatcher.new(o_in, @onto)
    om.alignment_repo.clear!
    om.insert_graph_pattern_ontology!
    om.add_correspondence!(@c1)
    om.add_correspondence!(@c2)
  end
end