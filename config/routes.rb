RepMine::Application.routes.draw do  resources :patterns do 
    
    get "/translate/:ontology_id", :to => "patterns#translate", :as => :translate_to_ontology
    get "/query/:ontology_id", :to => "patterns#query", :as => :query_for_ontology
    post "/run_on_repository/:repository_id", :to => "patterns#run_on_repository", :as => :run_on_repository
    post "/save_correspondence/:target_pattern_id", :to => "patterns#save_correspondence", :as => :save_correspondence
    
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
    
    get :missing_concepts, :on => :collection
    post :run_on_repository
    get :autocomplete_tag_name, :on => :collection
  end

  resources :repositories do
    get :extract_schema
  end
  
  resources :ontologies do
    get :autocomplete_ontology_group, :on => :collection
  end
  
  root :to => "patterns#index"
end
