class CorrespondencesController < ApplicationController

  layout false

  def create
    sources = (params[:source_element_ids] || []).reject{|x| x.blank?}.first
    targets = (params[:target_element_ids] || []).reject{|x| x.blank?}.first
    matched_concepts = []

    if sources.blank? || targets.blank?
      flash[:error] = "Missing input/output elements!"
    else
      input_elements = PatternElement.find(sources.split(","))
      output_elements = PatternElement.find(targets.split(","))
      begin
        @oc = Correspondence.from_elements(input_elements, output_elements)
        output_elements.first.pattern.prepare!
        flash[:notice] = "Correspondence saved!"
      rescue Correspondence::UnsupportedCorrespondence => e
        flash[:error] = "Could not save correspondence! #{e.message}"
      end
    end

    redirect_to pattern_unmatched_node_path(Pattern.find(params[:pattern_id]))
  end

  def index
    pattern = TranslationPattern.find(params[:pattern_id])
    matches = pattern.source_pattern.element_matches(pattern.ontologies)
    @correspondences = pattern.matching_groups
  end

  def destroy
    pattern = TranslationPattern.find(params[:pattern_id])
    PatternElementMatch.where(matching_element_id: params[:matching_elements], matched_element_id: params[:matched_elements]).destroy_all
    redirect_to pattern_translate_path(pattern)
  end

end