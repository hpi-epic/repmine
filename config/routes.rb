RepMine::Application.routes.draw do

  resources :queries do
    post "run_on_repository"
    get "editor"
    get "possible_relations"
    get "possible_attributes"
    post "store_pattern"
    post "store_permanently"    
    get :autocomplete_tag_name, :on => :collection
  end

  resources :repositories do
    get "extract_schema"
  end
  
  resources :ontologies  
  
  match "/delayed_job" => DelayedJobWeb, :anchor => false
  root :to => "queries#index"
end
