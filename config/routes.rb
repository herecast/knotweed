# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'

  # custom devise routing
  devise_scope :user do
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
      root to: 'dashboard#index'
    end

    devise_for :users, controllers: { sessions: 'sessions', registrations: 'registrations' }

    resources :payments, only: :index
    namespace :payments do
      resources :sends, only: :create
      resources :generates, only: %i[new create]
    end
    delete '/payments/:period_start/:period_end/cancel', to: 'payments#destroy', as: :cancel_payments
    resources :payment_recipients

    resources :users do
      member do
        put :update_subscription
      end
      resources :archivings, only: %i[new create], controller: 'users/archivings'
    end
    post '/users/admin-create', to: 'users#create', as: 'create_user'
    put '/users/:id/admin-update', to: 'users#update', as: 'update_user'

    get '/', to: 'dashboard#index', as: :dashboard
    get '/dashboard/total_sign_ins', to: 'dashboard#total_sign_ins', as: :total_sign_ins
    get 'dashboard/article_clicks', to: 'dashboard#article_clicks', as: :article_clicks
    get 'dashboard/clicks_by_category', to: 'dashboard#clicks_by_category', as: :clicks_by_category
    get 'dashboard/session_duration', to: 'dashboard#session_duration', as: :session_duration

    get 'contents/parent_options', to: 'contents#parent_select_options', as: :parent_select_options
    resources :contents, except: %i[show new create]
    post 'content/removals', to: 'contents/removals#create'
    delete 'content/removals', to: 'contents/removals#destroy'
    post 'content/facebook_scraping', to: 'contents/facebook_scrapings#create'
    resources :campaigns, except: %i[show destroy]
    resources :comments, only: %i[index update destroy]
    resources :business_profiles, except: [:destroy]
    namespace :business_profiles do
      resources :managers, only: [:create]
      delete '/managers', to: 'managers#destroy', as: 'delete_manager'
      resources :archivings, only: %i[create destroy]
      resources :claims, only: [:create]
    end
    resources :images, only: %i[create destroy update]
    resources :organizations, except: [:show] do
      resources :users, only: [:index], controller: 'organizations/users'
      resources :promotions, shallow: true
    end

    resources :locations, except: [:destroy]
    resources :business_locations

    resources :rewrites, except: [:show]

    resources :listservs do
      resources :campaigns, controller: :listserv_campaigns
    end
    resources :subscriptions

    resources :features

    get '/ics/event_instances/:id', to: 'api/v3/event_instances#show', defaults: { format: 'ics' }, as: :event_instances_ics
    get '/ics/events/:public_id', to: 'api/v3/users#events', defaults: { format: 'ics' }, as: :user_event_instances_ics

    get '/sidekiq_wrapper', to: 'sidekiq_wrapper#index'
  end

  # API
  namespace :api do
    namespace :v3, defaults: { format: 'json' } do
      get '/current_user', to: 'users#show'
      put '/current_user', to: 'users#update'
      post '/contents/:id/moderate', to: 'contents#moderate', as: :moderate

      get '/payment_reports', to: 'payment_reports#index', as: :payment_reports, defaults: { format: 'html' }

      namespace :users do
        resources :bookmarks, except: %i[show new edit], path: '/:user_id/bookmarks'
        resources :payments, only: :index, path: '/:user_id/payments'
        resources :metrics, only: :index, path: '/:user_id/metrics'
        resources :comments, only: :index, path: '/:id/comments'
        resources :contents, only: :index, path: '/:id/contents'
      end
      post 'promotion_banners/:promotion_banner_id/track_click', to: 'promotion_banners#track_click', as: :track_click
      post 'promotion_banners/:promotion_banner_id/track_load', to: 'promotion_banners#track_load', as: :track_load

      post 'promotion_banners/:id/impression', to: 'promotion_banners#track_impression', as: :track_impression
      get '/promotion_banners/:id/metrics', to: 'promotion_banners#metrics',
                                            as: :promotion_banner_metrics
      get '/promotions', to: 'promotion_banners#show'
      get '/promotions/:promotion_id', to: 'promotion_banners#show'
      get '/event_instances/active_dates', to: 'event_instances#active_dates'
      get '/event_instances/sitemap_ids', to: 'event_instances#sitemap_ids'

      resources 'event_instances', only: %i[index show]

      # deprecated
      post 'events/:id/impressions', to: 'metrics/contents/impressions#create'

      resources 'comments', only: %i[index create]
      post '/comments/unsubscribe_from_alerts', to: 'comments#unsubscribe_webhook'
      resources 'listservs', only: %i[show index]
      get '/venues', to: 'business_locations#index', as: :venues
      get '/venue_locations', to: 'business_locations#index', as: :venue_locations,
                              defaults: { autocomplete: true, max_results: 5 }
      get '/venues/:id/location', to: 'business_locations#location'

      get '/locations/:id/closest', to: 'locations#closest', as: :closest
      get '/locations/locate', to: 'locations#locate'
      resources :locations, only: %i[index show]

      get '/feed', to: 'feed#index'

      get '/contents/sitemap_ids', to: 'contents#sitemap_ids'
      resources :contents, only: %i[show create update destroy] do
        post '/notifications', to: 'contents/notifications#create'
      end
      get '/contents/:id/metrics', to: 'contents#metrics', as: :content_metrics
      get '/contents/:id/similar_content', to: 'contents#similar_content', as: :similar_content
      # specifying path here to avoid deprecating the frontend even though we've changed
      # the modeling
      namespace :contents do
        get '/:content_id/promotions', to: 'promotions#index'
        post '/:content_id/promotions', to: 'promotions#create'
      end
      namespace :organizations do
        put    '/:organization_id/contents/:content_id',      to: 'contents#update'
        post   '/:organization_id/contents/:content_id/tags', to: 'contents/tags#create'
        delete '/:organization_id/contents/:content_id/tags', to: 'contents/tags#destroy'
        get    '/:name/validation', to: 'validations#show'
        get    '/subscriptions',    to: 'subscriptions#index'
        post   '/:organization_id/subscriptions', to: 'subscriptions#create'
        delete '/subscriptions/:id',              to: 'subscriptions#destroy'
        post   '/:organization_id/hides', to: 'hides#create'
        delete '/hides/:id',              to: 'hides#destroy'
      end
      get '/organizations/sitemap_ids', to: 'organizations#sitemap_ids'

      resources 'organizations', only: %i[index show update create] do
        resources :metrics, only: [:index], controller: 'organizations/metrics'
      end

      # deprecated
      post '/news/:id/impressions', to: 'metrics/contents/impressions#create'

      post '/users/logout', to: 'users#logout', as: :logout
      get '/user', to: 'users#verify'
      post '/users/email_confirmation', to: 'users#email_confirmation', as: :email_confirmation
      post '/users/resend_confirmation', to: 'users#resend_confirmation', as: :resend_confirmation
      post '/users/email_signin_link', to: 'users#email_signin_link', as: :email_signin_link
      resources 'images', only: %i[create update destroy]
      post '/images/upsert', to: 'images#upsert'

      delete '/content_locations/:id', to: 'content_locations#destroy'

      resources 'business_profiles', only: %i[index show create update], path: 'businesses'
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
      delete 'subscriptions/:key', to: 'subscriptions#destroy'
      delete 'subscriptions/:listserv_id/:email', to: 'subscriptions#destroy'

      put '/businesses/:id/feedback', to: 'business_feedbacks#update', as: :update_feedback
      get '/digests', to: 'digests#index'
      get '/digests/:id', to: 'digests#show'
      get '/features', to: 'features#index'
      post '/ad_metrics', to: 'promotion_banners#create_ad_metric'
      get '/promotion_coupons/:id', to: 'promotion_banners#show_promotion_coupon'
      post '/promotion_coupons/:id/request_email', to: 'promotion_banners#create_promotion_coupon_email'

      post '/metrics/contents/:id/impressions', to: 'metrics/contents/impressions#create'
      resources :content_permissions, only: :index
      post '/metrics/profiles/:id/impressions', to: 'metrics/profiles#impression'
      post '/metrics/profiles/:id/clicks', to: 'metrics/profiles#click'

      resources :mailchimp_webhooks, only: %i[index create]
    end
  end
end
