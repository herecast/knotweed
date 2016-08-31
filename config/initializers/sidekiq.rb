require 'sidekiq'
require 'sidekiq/web'

Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_token]
Sidekiq::Web.set :sessions, key: '_knotweed_sidekiq'
