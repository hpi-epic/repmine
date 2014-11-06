class CreateOntologyCorrespondences < ActiveRecord::Migration
  def change
    create_table :ontology_correspondences do |t|
      t.float :measure
      t.string :relation
      t.integer :input_ontology_id
      t.integer :output_ontology_id
      t.timestamps
    end
  end
end
