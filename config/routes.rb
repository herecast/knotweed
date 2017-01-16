Knotweed::Application.routes.draw do
  require 'sidekiq/web'

  authenticated :user do
    root :to => "dashboard#index"
    mount Sidekiq::Web, at: '/sidekiq'
  end

  devise_for :users, controllers: { sessions: 'sessions', registrations: 'registrations' }
  #custom devise routing
  devise_scope :user  do
    post '/api/v3/users/sign_in', to: 'sessions#create'
    post '/api/v3/users/sign_up', to: 'registrations#create'
    post '/api/v3/password_resets', to: 'api/v3/passwords#create'
    put '/api/v3/password_resets', to: 'api/v3/passwords#update'
  end
  resources :users do
    member do
      put :update_subscription
    end
  end
  post '/users/admin-create', to: 'users#create'
  put '/users/:id/admin-update', to: 'users#update'

  get "/", to: "dashboard#index", as: :dashboard
  get "/dashboard/total_sign_ins", to: "dashboard#total_sign_ins", as: :total_sign_ins
  get "dashboard/article_clicks", to: "dashboard#article_clicks", as: :article_clicks
  get "dashboard/clicks_by_category", to: "dashboard#clicks_by_category", as: :clicks_by_category
  get "dashboard/session_duration", to: "dashboard#session_duration", as: :session_duration

  get "contents/parent_options", to: "contents#parent_select_options", as: :parent_select_options
  resources :contents
  resources :campaigns, only: :index
  get "issues/select_options", to: "issues#select_options", as: :issue_select_options
  get "organizations/business_location_options", to: "organizations#business_location_options", as: :business_location_options
  resources :market_posts, except: [:destroy]
  resources :business_profiles, except: [:destroy]
  namespace :business_profiles do
    resources :managers, only: [:create]
    delete '/managers', to: 'managers#destroy', as: 'delete_manager'
    resources :archivings, only: [:create, :destroy]
    resources :claims, only: [:create]
  end
  resources :import_jobs
  resources :parsers
  resources :messages, except: [:show]
  resources :publish_jobs
  resources :wufoo_forms, except: [:show]
  resources :consumer_apps, except: [:show]
  resources :images, only: [:create, :destroy, :update]
  resources :organizations, except: [:show] do
    resources :promotions, shallow: true
  end

  get "organizations/update_content_sets", to: "organizations#update_content_sets", as: :update_content_sets
  resources :organizations
  resources :content_sets
  resources :contacts, only: [:create, :update, :edit, :destroy]
  resources :issues, only: [:new, :create, :update, :edit, :destroy, :show]
  resources :locations, only: [:create, :new, :edit]
  resources :business_locations
  resources :events, except: [:show, :destroy]
  put "destroy_event_instance", to: "events#destroy_event_instance", as: :destroy_event_instance

  resources :rewrites, except: [:show]

  resources :data_contexts
  resources :repositories
  resources :listservs do
    resources :campaigns, controller: :listserv_campaigns
  end
  resources :subscriptions
  resources :received_emails
  resources :listserv_contents

  get "repositories/:id/clear_published_contents", to: "repositories#clear_published_contents", as: :clear_published_contents

  post 'annotation_reports/create/:content_id', to: "annotation_reports#create", as: :create_annotation_report
  get 'annotation_reports/export/:content_id', to: "annotation_reports#export", as: :export_annotation_reports
  get 'annotation_reports/:annotation_report_id/annotations/:annotation_id/edit', to: "annotations#edit", as: :edit_annotation
  resources :annotation_reports, only: [:edit, :destroy]
  resources :features
  resources :market_categories, except: [:show]
  get 'annotation_reports/:id/table_row' => 'annotation_reports#table_row', as: :annotation_report_table_row

  get 'annotations/:id/accept(/:accepted)' => "annotations#accept_annotation", as: :accept_annotation

  get 'contacts/new(/:model(/:id))', to: "contacts#new", as: :new_contact

  post 'publish_jobs/contents_count' => "publish_jobs#contents_count", as: :contents_count
  get 'publish_jobs/contents_count/:id' => "publish_jobs#job_contents_count", as: :job_contents_count
  get 'publish_jobs/:id/file_archive.zip' => "publish_jobs#file_archive", as: :job_file_archive

  get "parsers/:parser_id/new_import_job" => "import_jobs#new", as: :new_import_job_for_parser

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
  get 'parsers/:id/parameters', to: "parsers#parameters"
  post '/contents/category_correction', to: 'contents#category_correction'
  post '/contents/category_correction_reviewed', to: 'contents#category_correction_reviwed'
  get '/ics/event_instances/:id', to: 'api/v3/event_instances#show', :defaults => {:format => 'ics'}, as: :event_instances_ics
  get '/ics/events/:public_id', to: 'api/v3/users#events', :defaults => {:format => 'ics'}, as: :user_event_instances_ics

  get '/sidekiq_wrapper', to: 'sidekiq_wrapper#index'

  # API
  namespace :api do
    namespace :v3, defaults: {format: 'json'} do
      get '/current_user', to: 'users#show'
      put '/current_user', to: 'users#update'
      resources 'events', only: [:create, :show, :update, :index]
      post '/contents/:id/moderate', to: 'contents#moderate', as: :moderate
      post 'promotion_banners/:promotion_banner_id/track_click', to: 'promotion_banners#track_click', as: :track_click
      post 'promotion_banners/:id/impression', to: 'promotion_banners#track_impression', as: :track_impression
      get '/promotion_banners/:id/metrics', to: 'promotion_banners#metrics',
        as: :promotion_banner_metrics
      resources 'promotion_banners', only: [:index]
      get '/promotions', to: 'promotion_banners#show'
      get '/promotions/:promotion_id', to: 'promotion_banners#show'
      resources 'event_instances', only: [:index, :show]
      resources 'comments', only: [:index, :create]
      resources 'listservs', only: [:show,:index]
      get '/venues', to: 'business_locations#index', as: :venues
      get '/venue_locations', to: 'business_locations#index', as: :venue_locations,
        defaults: { autocomplete: true, max_results: 5 }
      get '/locations', to: 'locations#index', as: :locations
      resources 'contents', only: [:index]
      get '/contents/:id/similar_content', to: 'contents#similar_content', as: :similar_content
      get '/contents/:id/metrics', to: 'contents#metrics', as: :content_metrics
      # specifying path here to avoid deprecating the frontend even though we've changed
      # the modeling
      resources 'organizations', only: [:index, :show, :update]
      resources 'news'
      post '/news/:id/impressions', to: 'news#create_impression'
      resources 'talk', only: [:index, :show, :create, :update]
      resources 'market_posts', only: [:index, :show, :create, :update]
      get '/market_posts/:id/contact', to: 'market_posts#contact', as: :market_post_contact
      get '/weather', to: 'users#weather', as: :weather
      post '/users/logout', to: 'users#logout', as: :logout
      get '/user', to: 'users#verify'
      get '/dashboard', to: 'contents#dashboard', as: :dashboard
      post '/users/email_confirmation', to: 'users#email_confirmation', as: :email_confirmation
      post '/users/resend_confirmation', to: 'users#resend_confirmation', as: :resend_confirmation
      resources 'images', only: [:create, :update, :destroy]

      resources 'business_profiles', only: [:index, :show, :create, :update], path: 'businesses'
      resources 'business_categories', only: [:index]
      post '/businesses/:id/feedback', to: 'business_feedbacks#create', as: :leave_feedback
      post '/emails', to: 'emails#create'
      get '/subscriptions/unsubscribe_from_mailchimp', to: 'subscriptions#verify_mc_webhook'
      post '/subscriptions/unsubscribe_from_mailchimp', to: 'subscriptions#unsubscribe_from_mailchimp'
      get '/subscriptions', to: 'subscriptions#index'
      get '/subscriptions/:key', to: 'subscriptions#show'
      post '/subscriptions', to: 'subscriptions#create'
      patch'/subscriptions/:key', to: 'subscriptions#update'
      patch '/subscriptions/:key/confirm', to: 'subscriptions#confirm'
      delete "subscriptions/:key", to: 'subscriptions#destroy'
      delete "subscriptions/:listserv_id/:email", to: 'subscriptions#destroy'
      post '/registrations/confirmed', to: 'confirmed_registrations#create'

      resources :listserv_contents, only: [:show,:update]
      put '/businesses/:id/feedback', to: 'business_feedbacks#update', as: :update_feedback
      resources :content_reports, only: :index
      resources :promotion_banner_reports, only: :index
      get '/digests', to: 'digests#index'
      get '/digests/:id', to: 'digests#show'
      get '/features', to: 'features#index'
      get '/market_categories', to: 'market_categories#index'
      get '/market_categories/:id', to: 'market_categories#show'
    end
  end

end
