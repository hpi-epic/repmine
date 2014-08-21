RepMine::Application.routes.draw do
  resources :swe_patterns

  resources :patterns do
    get 'missing_concepts'
    resources :nodes do
      get "fancy_rdf_string"
      resources :type_expressions do
        post "add_below"
        post "add_same_level"
        post "delete"        
      end
    end
    
    resources :relation_constraints
    resources :attribute_constraints
    get :editor
    get :translator
    post :run_on_repository
    post :reset
    get :autocomplete_tag_name, :on => :collection
  end

  resources :repositories do
    get "extract_schema"
  end
  
  resources :ontologies
  
  match "/delayed_job" => DelayedJobWeb, :anchor => false
  root :to => "patterns#index"
end
