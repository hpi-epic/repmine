RepMine::Application.routes.draw do

  resources :swe_patterns


  resources :attribute_constraints
  resources :relation_constraints

  resources :patterns do
    resources :nodes
    resources :relation_constraints
    resources :attribute_constraints
    get "editor"
    get "translator"
    get "run_on_repository"
    get :autocomplete_tag_name, :on => :collection
  end

  resources :repositories do
    get "extract_schema"
  end
  
  resources :ontologies
  
  match "/delayed_job" => DelayedJobWeb, :anchor => false
  root :to => "patterns#index"
end
