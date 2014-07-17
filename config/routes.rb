Knotweed::Application.routes.draw do

  resources :promotions


  authenticated :user do
    root :to => "application#dashboard"
  end
  devise_for :users
  root :to => redirect("/users/sign_in")
  resources :users
  
  get "/", to: "admin#dashboard", as: :dashboard
  resources :contents, except: [:destroy]
  get "issues/select_options", to: "issues#select_options", as: :issue_select_options
  resources :import_jobs
  resources :parsers
  resources :publish_jobs
  resources :images
  resources :publications
  get "organizations/update_content_sets", to: "organizations#update_content_sets", as: :update_content_sets
  resources :organizations
  resources :content_sets
  resources :contacts, only: [:create, :update, :edit, :destroy]
  resources :issues, only: [:new, :create, :update, :edit, :destroy, :show]
  resources :locations, only: [:create, :update, :new, :edit, :destroy]
  resources :business_locations, only: [:create, :update, :new, :edit, :destroy]

  resources :data_contexts
  resources :repositories
  get "repositories/:id/clear_published_contents", to: "repositories#clear_published_contents", as: :clear_published_contents

  match 'annotation_reports/create/:content_id', to: "annotation_reports#create", as: :create_annotation_report
  match 'annotation_reports/export/:content_id', to: "annotation_reports#export", as: :export_annotation_reports
  match 'annotation_reports/:annotation_report_id/annotations/:annotation_id/edit', to: "annotations#edit", as: :edit_annotation
  resources :annotation_reports, only: [:edit, :destroy]
  get 'annotation_reports/:id/table_row' => 'annotation_reports#table_row', as: :annotation_report_table_row

  match 'annotations/:id/accept(/:accepted)' => "annotations#accept_annotation", as: :accept_annotation

  match 'contacts/new(/:model(/:id))', to: "contacts#new", as: :new_contact

  match 'publish_jobs/contents_count' => "publish_jobs#contents_count", as: :contents_count
  match 'publish_jobs/contents_count/:id' => "publish_jobs#job_contents_count", as: :job_contents_count
  match 'publish_jobs/:id/file_archive.zip' => "publish_jobs#file_archive", as: :job_file_archive

  match "parsers/:parser_id/new_import_job" => "import_jobs#new", as: :new_import_job_for_parser

  # NOTE: these calls must end in :repository_id so that the javascript
  # that updates the action buttons on the onesie page works correctly
  get "contents/:id/publish/:method/repository/:repository_id", to: "contents#publish", as: :publish_content
  get "contents/:id/generate_gate_xml/repository/:repository_id", to: "contents#rdf_to_gate", as: :rdf_to_gate
  
  get 'import_jobs/:id/run_job', to: 'import_jobs#run_job', as: :run_import_job
  delete 'import_jobs/:id/cancel', to: 'import_jobs#cancel_job', as: :cancel_import_job
  get 'import_jobs/:id/archive', to: 'import_jobs#archive', as: :archive_import_job
  get 'publish_jobs/:id/run_job', to: 'publish_jobs#run_job', as: :run_publish_job
  delete 'publish_jobs/:id/cancel', to: 'publish_jobs#cancel_job', as: :cancel_publish_job
  get 'publish_jobs/:id/archive', to: 'publish_jobs#archive', as: :archive_publish_job
  
  match 'parsers/:id/parameters', to: "parsers#parameters"

  # API
  namespace :api do
    post 'contents/create_and_publish', to: 'contents#create_and_publish', as: :create_and_publish_content
    get 'contents/:id/get_tree', to: 'contents#get_tree', as: :get_tree
    post 'category_corrections', to: 'category_corrections#create'
  end

end
