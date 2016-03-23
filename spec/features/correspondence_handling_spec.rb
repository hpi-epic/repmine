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
    expect(page).to have_xpath("//input[@value='#{@c1.id}']")
    expect(page).to have_xpath("//input[@value='#{@c2.id}']")
    find(:xpath, "//input[@name='correspondence_id[[#{@pattern.nodes.first.id}]]'][@value='#{@c2.id}']").set(true)
    find(:xpath, "//input[@name='correspondence_id[[#{@pattern.attribute_constraints.first.id}]]'][@value='#{@c2.id}']").set(true)
    click_button("Prepare!")
    expect(current_path).to eq(pattern_translate_path(TranslationPattern.first))
    tp = TranslationPattern.first
    expect(tp.pattern_elements).to_not be_empty
    target_node = tp.pattern_elements.first
    expect(target_node).to_not be_nil
    expect(target_node.rdf_type).to eq(@c2.entity2)
  end

  it "should allow users to pick manual mode instead of using one of the preset versions" do
    create_conflict()
    prepare_tp()
    visit(pattern_correspondence_selection_path(@tp))
    #print page.html
    expect(page).to have_xpath("//input[@name='correspondence_id[[#{@pattern.nodes.first.id}]]'][@value='0']")
    find(:xpath, "//input[@name='correspondence_id[[#{@pattern.nodes.first.id}]]'][@value='0']").set(true)
    find(:xpath, "//input[@name='correspondence_id[[#{@pattern.attribute_constraints.first.id}]]'][@value='0']").set(true)
    click_button("Prepare!")
    expect(current_path).to eq(pattern_translate_path(@tp))
    expect(@tp.pattern_elements).to be_empty
  end

  def create_conflict()
    @pattern = FactoryGirl.create(:pattern)
    o_in = @pattern.ontologies.first
    @onto = FactoryGirl.create(:ontology)
    @c1 = FactoryGirl.create(:simple_correspondence, onto1: o_in, entity1: @pattern.nodes.first.rdf_type, onto2: @onto)
    @c2 = FactoryGirl.create(:hardway_complex, onto1: o_in, onto2: @onto)
    @c3 = FactoryGirl.create(:simple_correspondence, onto1: o_in, entity1: @pattern.attribute_constraints.first.rdf_type, onto2: @onto)
    om = OntologyMatcher.new(o_in, @onto)
    om.alignment_repo.clear!
    om.insert_graph_pattern_ontology!
    om.add_correspondence!(@c1)
    om.add_correspondence!(@c2)
    om.add_correspondence!(@c3)
  end

  def prepare_tp()
    @tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@onto])
    begin
      @tp.prepare!
    rescue TranslationPattern::AmbiguousTranslation => e
    end
  end
end