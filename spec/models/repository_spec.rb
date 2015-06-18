# == Schema Information
#
# Table name: repositories
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  db_name       :string(255)
#  db_username   :string(255)
#  db_password   :string(255)
#  host          :string(255)
#  port          :integer
#  description   :text
#  ontology_id   :integer
#  type          :string(255)
#  rdbms_type_cd :integer
#

require 'rails_helper'

RSpec.describe Repository, :type => :model do

  it "should return a new instance for known types" do
    assert_not_nil Repository.for_type("RdfRepository")
  end

  it "should return nil for unknown types" do
    assert_nil Repository.for_type("ThisIsNotARepositoryType")
  end

end
