class AddRepositoryIdAndTypeFieldToOntologies < ActiveRecord::Migration
  def change
    add_column :ontologies, :type, :string
    add_column :ontologies, :repository_id, :integer
  end
end
