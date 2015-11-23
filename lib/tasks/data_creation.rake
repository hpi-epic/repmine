namespace :data do
  task :create_seon => [:environment] do
    create_repository()
    transform_issues()
    transform_commits()
  end

  def transform_commits
    repo = Neo4jRepository.where(:name => "SWT2 Github").first
    res = repo.query_result("MATCH (n:`GithubCommit`)-[:author]-(a:`GithubUser`) RETURN n.html_url, a.html_url")
    stmts = []
    res.each do |ci|
      commit = RDF::Resource.new(ci[0])
      user = RDF::Resource.new(ci[1])
      stmts << [commit, RDF.type, seon[:commit]]
      stmts << [user, RDF.type, seon[:committer]]
      stmts << [user, seon[:performs_commit], commit]
      stmts << [commit, seon[:carried_out_by],user]
    end

    res = repo.query_result("MATCH (n:`GithubCommit`)-[:files]-(f:`GithubFileChange`) WHERE has(f.status) RETURN n.html_url, f.html_url, f.filename")
    res.each do |ci|
      commit = RDF::Resource.new(ci[0])
      version = RDF::Resource.new(ci[1])
      file = RDF::Resource.new("http://github.com/hpi-swt2/event-und-raumplanung/" + ci[2])
      stmts << [file,RDF.type,seon[:file]]
      stmts << [version,RDF.type,seon[:version]]
      stmts << [commit,seon[:constitutesVersion],version]
      stmts << [version,seon[:isVersionOf],file]
    end
    upload_statements(stmts)
  end

  def transform_issues()
    repo = Neo4jRepository.where(:name => "SWT2 Github").first
    res = repo.query_result("MATCH (n:`GithubIssue`), (c:`GithubIssueComment`)-[:user]-(a:`GithubUser`) WHERE c.issue_url = n.url RETURN n.html_url, c.html_url, a.html_url")
    stmts = []
    res.each do |ii|
      issue = RDF::Resource.new(ii[0])
      comment = RDF::Resource.new(ii[1])
      user = RDF::Resource.new(ii[2])
      stmts << [user, RDF.type, seon[:stakeholder]]
      stmts << [issue, RDF.type, seon[:issue]]
      stmts << [comment, RDF.type, seon[:comment]]
      stmts << [comment, seon[:isCommentOf], issue]
      stmts << [comment, seon[:isCommentedBy], user]
      stmts << [comment, seon[:hasAuthor], user]
    end
    upload_statements(stmts)
  end

  def upload_statements(stmts)
    repo = RdfRepository.where(:name => "Test Project (SEON)").first
    ag = AgraphConnection.new(repo.db_name.split("/").last)
    puts "inserting #{stmts.size} statements"
    ag.repository.insert(*stmts)
    ag.remove_duplicates!()
  end

  def create_repository()
    ontology = Ontology.where(short_name: "seon.owl").first
    repo = RdfRepository.where(name: "Test Project (SEON)", db_name: "repositories/seon_data", ontology_url: ontology.url).first_or_create
    config = RepMine::Application.config.database_configuration["agraph"]
    repo.update_attributes(db_username: config["username"], db_password: config["password"], port: config["port"], host: config["host"])
    ag = AgraphConnection.new("seon_data")
    ag.insert_file!(ontology.local_file_path)
  end

  def seon
    {
      :commit => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/history.owl#Commit"),
      :committer => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/history.owl#Committer"),
      :performs_commit => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/history.owl#performsCommit"),
      :carried_out_by => RDF::Resource.new("http://se-on.org/ontologies/general/2012/02/main.owl#isCarriedOutBy"),
      :file => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/history.owl#FileUnderVersionControl"),
      :constitutesVersion => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/history.owl#constituesVersion"),
      :isVersionOf => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/history.owl#isVersionOf"),
      :version => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/history.owl#Version"),
      :comment => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/issues.owl#Comment"),
      :issue => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/issues.owl#Issue"),
      :stakeholder => RDF::Resource.new("http://se-on.org/ontologies/general/2012/2/main.owl#Stakeholder"),
      :isCommentedBy => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/issues.owl#isCommentedBy"),
      :isCommentOf => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/issues.owl#isCommentOf"),
      :hasAuthor => RDF::Resource.new("http://se-on.org/ontologies/general/2012/2/main.owl#hasAuthor")
    }
  end
end