namespace :data do
  task :export => [:environment] do
    fn = Rails.root.join("db", "seeds", "extraction_descriptions.rb").to_s
    SeedFu::Writer.write(fn, :class_name => ExtractionDescription){|writer|
      ExtractionDescription.find_each{|ed| 
        writer << ed.attributes.except(*%w'created_at updated_at')
      }
    }
    
    fn = Rails.root.join("db", "seeds", "mappings.rb").to_s
    SeedFu::Writer.write(fn, :class_name => Mapping) do |writer|
      Mapping.where("parent_id" => nil).each do |ed|
        Mapping.each_with_level(ed.self_and_descendants) do |em, level|
          writer << em.attributes.except(*%w'created_at updated_at lft rgt depth')
        end
      end
    end
  end
end
