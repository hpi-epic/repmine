class CreateCorrespondences < ActiveRecord::Migration
  def change
    create_table :correspondences do |t|
      t.string :relation
      t.float :measure
      t.integer :onto1_id
      t.integer :onto2_id
      t.text :mapping_key
      t.string :type
    end
  end
end
