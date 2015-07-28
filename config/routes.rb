RepMine::Application.routes.draw do

  resources :patterns do
    get :query
    post :query
    get "translate/:ontology_id", :as => :translate, :to => "patterns#translate"
    post :process_patterns, :on => :collection
    get :monitor, :on => :collection
    post "/save_correspondence/:output_pattern_id", :to => "patterns#save_correspondence", :as => :save_correspondence

    resources :nodes do
      get :fancy_rdf_string
      resources :type_expressions do
        post :add_below
        post :add_same_level
        post :delete
      end
    end

    resources :relation_constraints do
      get :static
    end

    resources :attribute_constraints do
      get :static
    end

    get :autocomplete_tag_name, :on => :collection
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

  root :to => "patterns#index"
end
