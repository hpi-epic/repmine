# == Schema Information
#
# Table name: ontologies
#
#  id          :integer          not null, primary key
#  url         :string(255)
#  description :text
#  short_name  :string(255)
#  group       :string(255)
#  does_exist  :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :url do |n|
    "http://example.org/ontology_#{n}"
  end

  factory :ontology do
    url
  end
end
