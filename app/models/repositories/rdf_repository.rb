class RdfRepository < Repository

  attr_accessor :sparql_client

  def self.model_name
    return Repository.model_name
  end

  def self.default_port
    10035
  end

  def sparql_client
    @sparql_client ||= SPARQL::Client.new("http://#{db_username}:#{db_password}@#{host}:#{port}/#{db_name}")
    return @sparql_client
  end

  # builds an ontology from a corresponding entry in the dataset
  # TODO: think about knowlegebases with multiple <blub> a owl:Ontology . statements ...
  def build_ontology
    query = sparql_client.select(:ont).where([:ont, RDF.type, RDF::OWL.Ontology])
    raise "no ontology url found within the knowledge base" if query.solutions.empty?
    url = query.solutions.first[:ont].to_s
    # not entirely sure, where these should go groupwhise...but let's put the in extracted for now
    self.ontology = Ontology.where(:url => url).first_or_create(:group => "Extracted")
    self.save
  end

  # as we already build a proper ontology, we don't have to extract one
  def create_ontology!
    return true
  end

  def type_statistics
    blacklist = [RDF::RDFS.Class, RDF::OWL.Class]
    statistics = {}
    query = sparql_client.select(:x, :y).where([:x, RDF.type, :y])
    query.each_solution do |solution|
      next unless blacklist.index(solution[:y]).nil?
      statistics[solution[:y].to_s] ||= 0
      statistics[solution[:y].to_s] += 1
    end
    return statistics.collect{|k,v| [k,v]}
  end
end
