RepMine::Application.routes.draw do

  resources :patterns do
    get :query
    post :query
    get "translate/:target_id", :as => :translate, :to => "patterns#translate"
    post :transmogrify, :on => :collection
    get :monitor, :on => :collection
    post :save_correspondence
    get :unmatched_node

    get :autocomplete_tag_name, :on => :collection
    resources :nodes, :only => [:create]
  end

  resources :relation_constraints do
    get :static
  end

  resources :nodes do
    get :fancy_rdf_string
    resources :type_expressions do
      post :add_below
      post :add_same_level
      post :delete
    end
  end

  resources :attribute_constraints do
    get :static
    get :magic
  end

  resources :metrics do
    post :create_operator
    post :create_node
    post :create_connection
    post :destroy_connection
    post :monitor, :on => :collection
    get :autocomplete_tag_name, :on => :collection
  end

  resources :metric_nodes, :only => [:update, :destroy, :show] do
    resources :aggregations, :only => [:create, :destroy]
  end

  resources :repositories do
    get :extract_schema
  end

  resources :ontologies do
    get :autocomplete_ontology_group, :on => :collection
  end

  resources :monitoring_tasks do
    get :csv_results
    get :show_results
    post :run
    get :check, :on => :collection
  end

  resources :services

  root :to => "patterns#index"
end