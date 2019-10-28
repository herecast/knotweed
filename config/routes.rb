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

  get '/' => redirect('/admin')

  # /admin/...
  scope '/admin' do
    authenticated :user do
      mount Sidekiq::Web, at: '/sidekiq'
      root to: 'dashboard#index'
    end

    get "/queue-status", to: 'sidekiq_queues#show'

    devise_for :users, controllers: { sessions: 'sessions', registrations: 'registrations' }

    resources :payments, only: :index
    namespace :payments do
      resources :sends, only: :create
      resources :generates, only: %i[new create]
    end
    resources :ad_reports, only: :index
    delete '/payments/:period_start/:period_end/cancel', to: 'payments#destroy', as: :cancel_payments
    resources :payment_recipients

    get '/users/search', to: 'users/search#index', as: :user_search
    resources :users do
      member do
        put :update_subscription
      end
      resources :archivings, only: %i[new create], controller: 'users/archivings'
      resources :managers, only: %i[create destroy], controller: 'users/managers'
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

    resources :images, only: %i[create destroy update]
    resources :organizations, except: [:show] do
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

    get '/sidekiq_wrapper', to: 'sidekiq_wrapper#index'
  end

  # API
  namespace :api do
    namespace :v3, defaults: { format: 'json' } do
      post '/users/logout',              to: 'users/sessions#destroy', as: :logout
      get  '/user',                      to: 'users#index'
      post '/users/email_confirmation',  to: 'users/confirmations#create', as: :email_confirmation
      post '/users/resend_confirmation', to: 'users/confirmations#update', as: :resend_confirmation

      get '/current_user',    to: 'current_users#show'
      put '/current_user',    to: 'current_users#update'

      namespace :current_users do
        post '/password_validation', to: 'passwords#show'
      end

      get '/casters/follows', to: 'casters#index'
      get '/casters',         to: 'casters#show'

      namespace :casters do
        resources :bookmarks, except: %i[show new edit], path: '/:caster_id/bookmarks'
        resources :sitemap_ids, only: :index
        post   '/:caster_id/follows', to: 'follows#create'
        delete '/follows/:id',        to: 'follows#destroy'

        post   '/:caster_id/hides',   to: 'hides#create'
        delete '/hides/:id',          to: 'hides#destroy'

        get  '/handles/validation',      to: 'handles#show'
        get  '/emails/validation',       to: 'emails#show'

        get '/:id/contents', to: 'contents#index'
      end

      get '/casters/:id', to: 'casters#show'
     
      post '/contents/:content_id/moderate', to: 'contents/moderations#create'

      get '/payment_reports', to: 'payment_reports#index', as: :payment_reports, defaults: { format: 'html' }

      namespace :users do
        resources :payments, only: :index, path: '/:user_id/payments'
        resources :metrics, only: :index, path: '/:user_id/metrics'
        resources :publisher_agreements, only: :create, path: '/:user_id/publisher_agreements'
      end

      post 'promotion_banners/:promotion_banner_id/track_click', to: 'promotion_banners#track_click', as: :track_click
      post 'promotion_banners/:promotion_banner_id/track_load', to: 'promotion_banners#track_load', as: :track_load

      post 'promotion_banners/:id/impression', to: 'promotion_banners#track_impression', as: :track_impression
      get '/promotion_banners/:id/metrics', to: 'promotion_banners#metrics',
                                            as: :promotion_banner_metrics
      get '/promotions', to: 'promotion_banners#show'
      get '/promotions/:promotion_id', to: 'promotion_banners#show'
      get '/event_instances/active_dates', to: 'event_instances/active_dates#index'
      get '/event_instances/sitemap_ids', to: 'event_instances/sitemap_ids#index'

      # deprecated
      post 'events/:id/impressions', to: 'metrics/contents/impressions#create'

      resources 'comments', only: %i[index create]
      post '/comments/unsubscribe_from_alerts', to: 'comments#unsubscribe_webhook'
      get '/venues', to: 'business_locations#index', as: :venues
      get '/venue_locations', to: 'business_locations#index', as: :venue_locations,
                              defaults: { autocomplete: true, max_results: 5 }

      get '/locations/locate', to: 'locations/finds#show'
      resources :locations, only: %i[index show]

      get '/feed', to: 'contents#index'

      get '/contents/sitemap_ids', to: 'contents/sitemap_ids#index'
      resources :contents, only: %i[show create update destroy] do
        post '/notifications', to: 'contents/notifications#create'
      end
      get '/contents/:content_id/similar_content', to: 'contents/similar_contents#index'
      get '/contents/:content_id/metrics', to: 'contents/metrics#index'
      # specifying path here to avoid deprecating the frontend even though we've changed
      # the modeling
      namespace :contents do
        get '/:content_id/promotions', to: 'promotions#index'
        post '/:content_id/promotions', to: 'promotions#create'
      end  

      get '/organizations/sitemap_ids', to: 'organizations/sitemap_ids#index'

      # deprecated
      post '/news/:id/impressions', to: 'metrics/contents/impressions#create'

      
      resources 'images', only: %i[create update destroy]

      delete '/content_locations/:id', to: 'content_locations#destroy'

      post '/emails', to: 'emails#create'
      get '/subscriptions', to: 'subscriptions#index'
      get '/subscriptions/:key', to: 'subscriptions#show'
      post '/subscriptions', to: 'subscriptions#create'
      patch'/subscriptions/:key', to: 'subscriptions#update'
      patch '/subscriptions/:key/confirm', to: 'subscriptions#confirm'
      delete 'subscriptions/:key', to: 'subscriptions#destroy'
      delete 'subscriptions/:listserv_id/:email', to: 'subscriptions#destroy'

      get '/digests', to: 'digests#index'
      get '/digests/:id', to: 'digests#show'
      get '/features', to: 'features#index'
      get '/promotion_coupons/:id', to: 'promotion_banners#show_promotion_coupon'
      post '/promotion_coupons/:id/request_email', to: 'promotion_banners#create_promotion_coupon_email'

      post '/metrics/contents/:id/impressions', to: 'metrics/contents/impressions#create'
      resources :content_permissions, only: :index

      post '/metrics/profiles/:id', to: 'metrics/profiles#create'

      resources :mailchimp_webhooks, only: %i[index create]
      resources :rewrites, only: :index
    end
  end
end
