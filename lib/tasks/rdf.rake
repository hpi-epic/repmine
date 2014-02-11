namespace :rdf do
  desc "creates vocabulary classes for all Ontologies that are in the RAILS_ENV database"
  task :create_vocabularies => [:environment] do
    require 'rdf/cli/vocab-loader'
    Ontology.all.each do |ont|
      c = RDF::VocabularyLoader.new
      c.prefix = ont.prefix_url
      c.source = ont.url
      c.class_name = ont.vocabulary_class_name
      f = File.open(Rails.root.join("app", "models", "vocabularies", c.class_name.underscore + ".rb"), "w+")
      c.output = f
      c.run
      f.close
    end
    
    desc "removes the previously created vocabularies from the respective folder"
    task :remove_vocabularies => [:environment] do
      
    end
  end
end