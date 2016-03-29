class RdfRepository < Repository

  attr_accessible :ontology_url
  attr_accessor :sparql_client

  validates :ontology_url, presence: true

  def self.default_port
    10035
  end

  def sparql_client
    @sparql_client ||= SPARQL::Client.new("http://#{db_username}:#{db_password}@#{host}:#{port}/#{db_name}")
    return @sparql_client
  end

  def build_ontology
    self.ontology = Ontology.where(:url => ontology_url).first_or_create(:group => "Extracted")
    self.save
  end

  def analyze_repository
    return true
  end

  def type_statistics
    blacklist = [RDF::RDFS.Class, RDF::OWL.Class, RDF::OWL.DatatypeProperty, RDF::OWL.ObjectProperty]
    statistics = {}
    query = sparql_client.select(:x, :y).where([:x, RDF.type, :y])
    query.each_solution do |solution|
      next unless blacklist.index(solution[:y]).nil?
      statistics[solution[:y].to_s] ||= 0
      statistics[solution[:y].to_s] += 1
    end
    return statistics.collect{|k,v| [k,v]}
  end

  # iterates over all results and returns a hash with string keys and objects based on the returned literal values
  def results_for_query(query)
    sparql_client.query(query).collect do |solution|
      Hash[solution.collect{|key, val| [key.to_s, val.is_a?(RDF::Literal) ? val.object :  val.to_s]}.map {|x| [x[0], x[1]]}]
    end
  end
end