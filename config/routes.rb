Knotweed::Application.routes.draw do

  authenticated :user do
    root :to => "dashboard#index"
  end
  devise_for :users, controllers: { sessions: 'sessions', registrations: 'registrations' }
  #custom devise routing
  devise_scope :user  do
    post '/api/v3/users/sign_in', to: 'sessions#create'
    post '/api/v3/users/sign_up', to: 'registrations#create'
    post '/api/v3/password_resets', to: 'api/v3/passwords#create'
    put '/api/v3/password_resets', to: 'api/v3/passwords#update'
  end
  root :to => redirect("#{"#{ENV['RAILS_RELATIVE_URL_ROOT']}" unless ENV['RAILS_RELATIVE_URL_ROOT'].nil?}/users/sign_in")
  resources :users
  
  get "/", to: "dashboard#index", as: :dashboard
  get "/dashboard/mixpanel_charts", to: "dashboard#mixpanel_charts", as: :mixpanel_charts
  get "/dashboard/total_sign_ins", to: "dashboard#total_sign_ins", as: :total_sign_ins
  get "dashboard/article_clicks", to: "dashboard#article_clicks", as: :article_clicks
  get "dashboard/clicks_by_category", to: "dashboard#clicks_by_category", as: :clicks_by_category
  get "dashboard/session_duration", to: "dashboard#session_duration", as: :session_duration

  get "contents/parent_options", to: "contents#parent_select_options", as: :parent_select_options
  resources :contents
  get "issues/select_options", to: "issues#select_options", as: :issue_select_options
  get "publications/business_location_options", to: "publications#business_location_options", as: :business_location_options
  resources :market_posts, except: [:destroy]
  resources :import_jobs
  resources :parsers
  resources :messages, except: [:show]
  resources :publish_jobs
  resources :wufoo_forms, except: [:show]
  resources :consumer_apps, except: [:show]
  resources :images
  resources :publications, except: [:show] do
    resources :promotions, shallow: true
  end

  get "organizations/update_content_sets", to: "organizations#update_content_sets", as: :update_content_sets
  resources :organizations
  resources :content_sets
  resources :contacts, only: [:create, :update, :edit, :destroy]
  resources :issues, only: [:new, :create, :update, :edit, :destroy, :show]
  resources :locations, only: [:create, :update, :new, :edit, :destroy]
  resources :business_locations
  resources :events, except: [:show, :destroy]

  resources :rewrites, except: [:show]

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
  get 'import_jobs/:id/stop_job', to: 'import_jobs#stop_ongoing_job', as: :stop_ongoing_import_job
  get 'publish_jobs/:id/run_job', to: 'publish_jobs#run_job', as: :run_publish_job
  delete 'publish_jobs/:id/cancel', to: 'publish_jobs#cancel_job', as: :cancel_publish_job
  get 'publish_jobs/:id/archive', to: 'publish_jobs#archive', as: :archive_publish_job
  
  match 'parsers/:id/parameters', to: "parsers#parameters"
  post '/contents/category_correction', to: 'contents#category_correction'
  post '/contents/category_correction_reviewed', to: 'contents#category_correction_reviwed'
  get '/ics/event_instances/:id', to: 'api/v3/event_instances#show', :defaults => {:format => 'ics'}, as: :event_instances_ics
  get '/ics/events/:public_id', to: 'api/v3/users#events', :defaults => {:format => 'ics'}, as: :user_event_instances_ics

  # API
  namespace :api do
    namespace :v3 do
      get '/current_user', to: 'users#show'
      put '/current_user', to: 'users#update'
      resources 'events', only: [:create, :show, :update]
      post '/contents/:id/moderate', to: 'contents#moderate', as: :moderate
      post 'promotion_banners/:promotion_banner_id/track_click', to: 'promotion_banners#track_click', as: :track_click
      get '/promotion_banners/:id/metrics', to: 'promotion_banners#metrics',
        as: :promotion_banner_metrics
      resources 'event_instances', only: [:index, :show, :destroy]
      resources 'comments', only: [:index, :create]
      resources 'listservs', only: [:index]
      get '/venues', to: 'business_locations#index', as: :venues
      get '/venue_locations', to: 'business_locations#index', as: :venue_locations,
        defaults: { autocomplete: true, max_results: 5 }
      get '/locations', to: 'locations#index', as: :locations
      get '/related_promotion', to: 'contents#related_promotion', as: :related_promotion
      get '/similar_content', to: 'contents#similar_content', as: :similar_content
      resources 'contents', only: [:index]
      get '/contents/:id/related_promotion', to: 'contents#related_promotion', as: :related_promotion
      get '/contents/:id/similar_content', to: 'contents#similar_content', as: :similar_content
      get '/contents/:id/metrics', to: 'contents#metrics', as: :content_metrics
      resources 'publications', only: [:index]
      resources 'news', only: [:index, :show]
      resources 'talk', only: [:index, :show, :create, :update]
      resources 'market_posts', only: [:index, :show, :create, :update]
      get '/market_posts/:id/contact', to: 'market_posts#contact', as: :market_post_contact
      get '/weather', to: 'users#weather', as: :weather
      post '/users/logout', to: 'users#logout', as: :logout
      get '/dashboard', to: 'contents#dashboard', as: :dashboard
      post '/users/email_confirmation', to: 'users#email_confirmation', as: :email_confirmation
      post '/users/resend_confirmation', to: 'users#resend_confirmation', as: :resend_confirmation
      resources 'images', only: [:create, :update, :destroy]
    end
  end

end
