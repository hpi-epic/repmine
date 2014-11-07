# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :url do |n|
    "http://example.org/ontology_#{n}"
  end
  
  factory :ontology do
    url
  end
end
