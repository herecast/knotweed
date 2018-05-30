Knotweed::Application.routes.draw do
  require 'sidekiq/web'

  #custom devise routing
  devise_scope :user  do
    post '/api/v3/users/sign_in', to: 'sessions#create'
    post '/api/v3/users/sign_up', to: 'registrations#create'
    post '/api/v3/users/oauth', to: 'sessions#oauth'
    post '/api/v3/password_resets', to: 'api/v3/passwords#create'
    put '/api/v3/password_resets', to: 'api/v3/passwords#update'

    post '/api/v3/users/sign_in_with_token', to: 'sessions#sign_in_with_token'
  end


  # /admin/...
  scope '/admin' do
    authenticated :user do
      mount Sidekiq::Web, at: '/sidekiq'
      root :to => "dashboard#index"
    end

    devise_for :users, controllers: { sessions: 'sessions', registrations: 'registrations' }

    resources :users do
      member do
        put :update_subscription
      end
      resources :archivings, only: [:new, :create], controller: 'users/archivings'
    end
    post '/users/admin-create', to: 'users#create', as: "create_user"
    put '/users/:id/admin-update', to: 'users#update', as: "update_user"

    get "/", to: "dashboard#index", as: :dashboard
    get "/dashboard/total_sign_ins", to: "dashboard#total_sign_ins", as: :total_sign_ins
    get "dashboard/article_clicks", to: "dashboard#article_clicks", as: :article_clicks
    get "dashboard/clicks_by_category", to: "dashboard#clicks_by_category", as: :clicks_by_category
    get "dashboard/session_duration", to: "dashboard#session_duration", as: :session_duration

    get "contents/parent_options", to: "contents#parent_select_options", as: :parent_select_options
    resources :contents, except: [:show, :new, :create]
    post "content/removals", to: "contents/removals#create"
    delete "content/removals", to: "contents/removals#destroy"
    post "content/facebook_scraping", to: "contents/facebook_scrapings#create"
    resources :campaigns, except: [:show, :destroy]
    resources :comments, only: [:index, :update, :destroy]
    resources :business_profiles, except: [:destroy]
    namespace :business_profiles do
      resources :managers, only: [:create]
      delete '/managers', to: 'managers#destroy', as: 'delete_manager'
      resources :archivings, only: [:create, :destroy]
      resources :claims, only: [:create]
    end
    resources :import_jobs
    resources :parsers
    resources :publish_jobs
    resources :consumer_apps, except: [:show]
    resources :images, only: [:create, :destroy, :update]
    resources :organizations, except: [:show] do
      resources :users, only: [:index], controller: 'organizations/users'
      resources :promotions, shallow: true
    end

    resources :contacts, only: [:create, :update, :edit, :destroy]
    resources :issues, only: [:new, :create, :update, :edit, :destroy, :show]
    resources :locations, except: [:destroy]
    resources :business_locations

    resources :rewrites, except: [:show]

    resources :repositories
    resources :listservs do
      resources :campaigns, controller: :listserv_campaigns
    end
    resources :subscriptions

    get "repositories/:id/clear_published_contents", to: "repositories#clear_published_contents", as: :clear_published_contents

    post 'annotation_reports/create/:content_id', to: "annotation_reports#create", as: :create_annotation_report
    get 'annotation_reports/export/:content_id', to: "annotation_reports#export", as: :export_annotation_reports
    get 'annotation_reports/:annotation_report_id/annotations/:annotation_id/edit', to: "annotations#edit", as: :edit_annotation
    resources :annotation_reports, only: [:edit, :destroy]
    resources :features
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

    resources :reports, except: [:show, :destroy] do
      resources :generations, only: [:create], controller: 'reports/generations'
    end
    resources :report_jobs, except: [:show] do
      resources :runs, only: [:create], controller: 'report_jobs/runs'
    end

    resources :report_recipients, except: [:index]
    resources :report_job_recipients, except: [:index, :create, :new]
  end

  # API
  namespace :api do
    namespace :v3, defaults: {format: 'json'} do
      get '/current_user', to: 'users#show'
      put '/current_user', to: 'users#update'
      post '/contents/:id/moderate', to: 'contents#moderate', as: :moderate
      namespace :users do
        resources :bookmarks, except: [:show, :new, :edit], path: '/:user_id/bookmarks'
        resources :comments, only: :index, path: '/:id/comments'
        resources :contents, only: :index, path: '/:id/contents'
      end
      post 'promotion_banners/:promotion_banner_id/track_click', to: 'promotion_banners#track_click', as: :track_click
      post 'promotion_banners/:promotion_banner_id/track_load', to: 'promotion_banners#track_load', as: :track_load

      post 'promotion_banners/:id/impression', to: 'promotion_banners#track_impression', as: :track_impression
      get '/promotion_banners/:id/metrics', to: 'promotion_banners#metrics',
        as: :promotion_banner_metrics
      resources 'promotion_banners', only: [:index]
      get '/promotions', to: 'promotion_banners#show'
      get '/promotions/:promotion_id', to: 'promotion_banners#show'
      get '/event_instances/active_dates', to: 'event_instances#active_dates'
      get '/event_instances/sitemap_ids', to: 'event_instances#sitemap_ids'

      resources 'event_instances', only: [:index, :show]

      #deprecated
      post 'events/:id/impressions', to: 'metrics/contents/impressions#create'

      resources 'comments', only: [:index, :create]
      post '/comments/unsubscribe_from_alerts', to: 'comments#unsubscribe_webhook'
      resources 'listservs', only: [:show,:index]
      get '/venues', to: 'business_locations#index', as: :venues
      get '/venue_locations', to: 'business_locations#index', as: :venue_locations,
        defaults: { autocomplete: true, max_results: 5 }
      get '/venues/:id/location', to: "business_locations#location"

      get '/locations/:id/closest', to: 'locations#closest', as: :closest
      get '/locations/locate', to: 'locations#locate'
      resources :locations, only: [:index, :show]

      get '/feed', to: 'feed#index'

      get '/contents/sitemap_ids', to: 'contents#sitemap_ids'
      resources :contents, only: [:show, :create, :update]
      get '/contents/:id/similar_content', to: 'contents#similar_content', as: :similar_content
      get '/contents/:id/metrics', to: 'contents#metrics', as: :content_metrics
      # specifying path here to avoid deprecating the frontend even though we've changed
      # the modeling
      namespace :contents do
        get '/:content_id/promotions', to: "promotions#index"
        post '/:content_id/promotions', to: "promotions#create"
      end
      namespace :organizations do
        put    '/:organization_id/contents/:content_id',      to: "contents#update"
        post   '/:organization_id/contents/:content_id/tags', to: "contents/tags#create"
        delete '/:organization_id/contents/:content_id/tags', to: "contents/tags#destroy"
      end
      get '/organizations/sitemap_ids', to: 'organizations#sitemap_ids'
      resources 'organizations', only: [:index, :show, :update]

      # deprecated
      post '/news/:id/impressions', to: 'metrics/contents/impressions#create'

      get '/weather', to: 'users#weather', as: :weather
      post '/users/logout', to: 'users#logout', as: :logout
      get '/user', to: 'users#verify'
      post '/users/email_confirmation', to: 'users#email_confirmation', as: :email_confirmation
      post '/users/resend_confirmation', to: 'users#resend_confirmation', as: :resend_confirmation
      post '/users/email_signin_link', to: 'users#email_signin_link', as: :email_signin_link
      resources 'images', only: [:create, :update, :destroy]
      post '/images/upsert', to: 'images#upsert'

      delete '/content_locations/:id', to: 'content_locations#destroy'

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

      put '/businesses/:id/feedback', to: 'business_feedbacks#update', as: :update_feedback
      resources :content_reports, only: :index
      resources :promotion_banner_reports, only: :index
      get '/promotion_banners/monthly_projection', to: 'promotion_banner_reports#show_monthly_projection'
      get '/digests', to: 'digests#index'
      get '/digests/:id', to: 'digests#show'
      get '/features', to: 'features#index'
      post '/ad_metrics', to: 'promotion_banners#create_ad_metric'
      get '/promotion_coupons/:id', to: 'promotion_banners#show_promotion_coupon'
      post '/promotion_coupons/:id/request_email', to: 'promotion_banners#create_promotion_coupon_email'
      get '/promotion_banner_reports/daily_report', to: 'promotion_banner_reports#show_daily_report'

      post '/metrics/contents/:id/impressions', to: 'metrics/contents/impressions#create'
      resources :content_permissions, only: :index
      post '/metrics/profiles/:id/impressions', to: 'metrics/profiles#impression'
      post '/metrics/profiles/:id/clicks', to: 'metrics/profiles#click'
    end
  end

end
