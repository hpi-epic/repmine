RepMine::Application.routes.draw do
  resources :swe_patterns

  resources :patterns do 
    
    resources :nodes do
      collection do
        post :translation_node
      end
      
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
    
    get :translate
    get :missing_concepts
    post :run_on_repository 
    post :reset
    get :autocomplete_tag_name, :on => :collection
  end

  resources :repositories do
    get :extract_schema
  end
  
  resources :ontologies
  root :to => "patterns#index"
end
