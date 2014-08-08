RepMine::Application.routes.draw do

  resources :type_expressions


  resources :swe_patterns

  resources :patterns do
    resources :nodes
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
