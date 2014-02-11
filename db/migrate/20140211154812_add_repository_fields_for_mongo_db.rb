class AddRepositoryFieldsForMongoDb < ActiveRecord::Migration
  def change
    add_column :repositories, :database_name, :string
  end
end
