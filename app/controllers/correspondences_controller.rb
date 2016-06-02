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
        @oc.update_attributes(user_provided: true)
        flash[:notice] = "Correspondence saved!"
      rescue Correspondence::UnsupportedCorrespondence => e
        flash[:error] = "Could not save correspondence! #{e.message}"
      end
    end

    redirect_to pattern_unmatched_node_path(Pattern.find(params[:pattern_id]))
  end

  def index
    @pattern = TranslationPattern.find(params[:pattern_id])
    @matching_groups = @pattern.matching_groups
  end

  def remove_matches
    PatternElementMatch.where(matched_element_id: params[:source_elements], matching_element_id: params[:target_elements]).destroy_all
    redirect_to pattern_translate_path(params[:pattern_id])
  end

  def destroy
    correspondence = Correspondence.find(params[:id])
    correspondence.destroy
    redirect_to(request.referer)
  end

end