class CreateOntologyCorrespondencePatternElements < ActiveRecord::Migration
  def change
    create_table :ontology_correspondences_pattern_elements do |t|
      t.integer :ontology_correspondence_id
      t.integer :input_element_id
      t.integer :output_element_id
    end
  end
end
