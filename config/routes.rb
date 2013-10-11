Knotweed::Application.routes.draw do
  mount RailsAdmin::Engine => '/rails_admin', :as => 'rails_admin'

  authenticated :user do
    root :to => 'contents#index'
  end
  root :to => "contents#index"
  devise_for :users
  resources :users
  
  resources :contents, only: ["show", "index"]

  namespace :admin do
    resources :contents, except: ["show"]
    resources :import_jobs
    resources :parsers
    match "parsers/:parser_id/new_import_job" => "import_jobs#new", as: :new_import_job_for_parser
    
    get 'import_jobs/:id/run_job', to: 'import_jobs#run_job', as: :run_job
    
    match 'parsers/:id/parameters', to: "parsers#parameters"
  end
end
