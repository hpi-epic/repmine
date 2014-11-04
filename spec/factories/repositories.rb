FactoryGirl.define do
  factory :repository do
    name "sample_repo"
    description "a simple repository without db connection"
    
    
    factory :rdf_repository, class: RdfRepository, parent: :repository do |u|
      type "RdfRepository"
    end
    
  end
  

end