class QueriesController < ApplicationController
  
  autocomplete :tag, :name, :class_name => 'ActsAsTaggableOn::Tag'
  
  def new
    @query = Query.new
  end
  
  def editor
    @query = Query.find(params[:query_id])
    @type_stuff = {} #@query.all_types_with_relations_and_attributes()
    @types = @query.ag_connection.type_hierarchy
  end
  
  def store_pattern
    @query = Query.find(params[:query_id])
    
    @query.save
    (params[:nodes] || {}).each_pair do |node_id, node_info|
      node = @query.query_nodes.build
      node.rdf_type = node_info["rdf_type"]
      node.root_node = true if node_id == "0"
      node.save      
      (node_info["attributes"] || {}).each_pair do |ii, attrib_constraint|
        node.query_attribute_constraints.create!(attrib_constraint)
      end
      @query.query_nodes << node
    end
    
    (params[:relations] || {}).each_pair do |relation_id, relation_info|
      source = @query.query_nodes[relation_info.delete("source").split("_").last.to_i]
      target = @query.query_nodes[relation_info.delete("target").split("_").last.to_i]
      qrc = @query.query_relation_constraints.create(relation_info)
      qrc.source = source
      qrc.target = target
      qrc.save
    end
    
    @query.save    
    redirect_to queries_path
  end
  
  def create
    @query = Query.new(params[:query])

    respond_to do |format|
      if @query.save
        @query.initialize_repository!
        format.html { redirect_to @query, notice: 'Ontology was successfully created.' }
        format.json { render json: @query, status: :created, location: @query }
      else
        format.html { render action: "new", notice: 'Could not create query' }
        format.json { render json: @query.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def show
    @query = Query.find(params[:id])
    redirect_to query_editor_path(@query)
  end
  
  def index
    @queries = Query.all
    @repositories = Repository.all
  end
  
  def destroy
    @query = Query.find(params[:id])
    qn = @query.name
    @query.destroy
    flash[:notice] = "Destroyed Query '#{qn}'"
    redirect_to queries_path
  end
  
  def run_on_graph
    @query = Query.find(params[:query_id])
    @graph = Graph.find(params[:graph_id])    
    @results = @graph.execute_query(@query)
  end
  
  def possible_relations
    @query = Query.find(params[:query_id])
    render :json => @query.possible_relations_between(params[:source], params[:target])
  end
  
  def possible_attributes
    @query = Query.find(params[:query_id])
    render :json => @query.possible_attributes_for(params[:node_class])
  end
  
  def store_permanently
    @query = Query.find(params[:query_id])
    @graph = Graph.find(params[:graph_id])
    @query.update_attributes(params[:query])
    flash[:notice] = "Stored query for later use!"
    redirect_to ([@graph, @query])
  end
end
