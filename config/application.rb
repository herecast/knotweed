require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  Bundler.require(:pry) unless ENV['RM_INFO'] || Rails.env.production?
  Bundler.require(:rubymine) if ENV['RM_INFO']
  Bundler.require(:default, Rails.env)
end

module Knotweed
  class Application < Rails::Application

    # don't generate RSpec tests for views and helpers
    config.generators do |g|

      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'


      g.view_specs false
      g.helper_specs false
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir[Rails.root.join('app', 'api_clients','**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'serializers', '**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'concerns', '**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'jobs','**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'services','**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'processes','**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'exceptions','**/')]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = { api_token: Figaro.env.postmark_api_token }
    config.action_mailer.asset_host = Figaro.env.default_host

    # Enable the asset pipeline
    config.assets.enabled = true

    # Set if not pre-compiling assets
    config.assets.compile = !!ENV.fetch('ASSETS_COMPILE', false)
    config.public_file_server.enabled = !!ENV.fetch('SERVE_STATIC_FILES', false)
    config.assets.precompile += %w(minimal.scss email/base.scss payment_reports.scss)

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'


    # Default ActiveJob adapter
    # jobs can configure their own individually
    config.active_job.queue_adapter = :sidekiq

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/api/v3/*', :headers => :any, :methods => [:get, :put, :patch, :post, :delete, :options]
      end
    end
    config.cache_store = :redis_store

    config.subtext = Hashie::Mash.new(config_for(:subtext))

    config.active_record.time_zone_aware_types = [:datetime]
  end
end
