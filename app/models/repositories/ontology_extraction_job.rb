# Delayed Job with progress extension to create an ontology for the repository
class OntologyExtractionJob < ProgressJob::Base
  
  attr_accessor :repository_id
  
  # not nice, but works...
  def initialize(*args)
    super()
    @progress_max = args[0][:progress_max] 
    @repository_id = args[0][:repository_id] 
  end
  
  def perform
    @repository = Repository.find(@repository_id)
    @repository.job = self
    @repository.analyze_repository(self)
    @repository.job = nil
  end
end