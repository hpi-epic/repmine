RepMine::Application.routes.draw do

  resources :patterns do
    resources :nodes    
    get "editor"
    get "possible_relations"
    get "possible_attributes"
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
