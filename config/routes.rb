RepMine::Application.routes.draw do

  resources :patterns do
    post "run_on_repository"
    get "editor"
    get "possible_relations"
    get "possible_attributes"
    # should become post after testing
    get "add_node"
    get :autocomplete_tag_name, :on => :collection
  end

  resources :repositories do
    get "extract_schema"
  end
  
  resources :ontologies  
  
  match "/delayed_job" => DelayedJobWeb, :anchor => false
  root :to => "patterns#index"
end
