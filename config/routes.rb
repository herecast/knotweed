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
    resources :contents, except: [:destroy]
    resources :import_jobs
    resources :parsers
    resources :publish_jobs
    resources :images
    resources :publications
    resources :contacts, only: [:create, :update, :new, :edit, :destroy]
    resources :locations, only: [:create, :update, :new, :edit, :destroy]

    get "publications/:id/contacts/new", to: "publications#new_contact", as: :publication_new_contact

    match 'publish_jobs/contents_count' => "publish_jobs#contents_count", as: :contents_count
    match 'publish_jobs/contents_count/:id' => "publish_jobs#job_contents_count", as: :job_contents_count

    match "parsers/:parser_id/new_import_job" => "import_jobs#new", as: :new_import_job_for_parser

    get "contents/:id/:method", to: "contents#publish", as: :publish_content
    
    get 'import_jobs/:id/run_job', to: 'import_jobs#run_job', as: :run_import_job
    delete 'import_jobs/:id/cancel', to: 'import_jobs#cancel_job', as: :cancel_import_job
    get 'publish_jobs/:id/run_job', to: 'publish_jobs#run_job', as: :run_publish_job
    delete 'publish_jobs/:id/cancel', to: 'publish_jobs#cancel_job', as: :cancel_publish_job
    
    match 'parsers/:id/parameters', to: "parsers#parameters"

  end
end
