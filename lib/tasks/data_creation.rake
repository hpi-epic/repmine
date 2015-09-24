namespace :data do
  task :create_seon => [:environment] do
    transform_issues()
    transform_commits()
  end

  def transform_commits
    repo = Repository.last
    res = repo.get_all_results("MATCH (n:`GithubCommit`)-[:author]-(a:`GithubUser`) RETURN n.url, a.url")["data"]
    stmts = []
    res.each do |ci|
      commit = RDF::Resource.new(ci[0])
      user = RDF::Resource.new(ci[1])
      stmts << [commit, RDF.type, seon[:commit]]
      stmts << [user, RDF.type, seon[:committer]]
      stmts << [user, seon[:performs_commit], commit]
      stmts << [commit, seon[:carried_out_by],user]
    end

    res = repo.get_all_results("MATCH (n:`GithubCommit`)-[:files]-(f:`GithubFileChange`) WHERE has(f.status) RETURN n.url, f.url, f.filename")["data"]
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
    repo = Repository.last
    res = repo.get_all_results("MATCH (n:`GithubIssue`), (c:`GithubIssueComment`)-[:user]-(a:`GithubUser`) WHERE c.issue_url = n.url RETURN n.url, c.url, a.url")["data"]
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
    end
    upload_statements(stmts)
  end

  def upload_statements(stmts)
    ag = AgraphConnection.new("seon_data")
    puts "inserting #{stmts.size} statements"
    ag.repository.insert(*stmts)
    ag.remove_duplicates!()
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
      :stakeholder => RDF::Resource.new("http://se-on.org/ontologies/general/2012/2/main.owl#hasAuthor"),
      :isCommentedBy => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/issues.owl#isCommentedBy"),
      :isCommentOf => RDF::Resource.new("http://se-on.org/ontologies/domain-specific/2012/02/issues.owl#isCommentOf")
    }
  end
end
