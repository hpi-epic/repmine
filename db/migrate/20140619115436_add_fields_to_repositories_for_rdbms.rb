class AddFieldsToRepositoriesForRdbms < ActiveRecord::Migration
  def change
    add_column :repositories, :rdbms_type_cd, :integer
  end
end
