Knotweed::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_files = !!ENV.fetch('SERVE_STATIC_FILES', false)

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = !!ENV.fetch('ASSETS_COMPILE', false)

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  custom_opts = {}
  if ENV.fetch('STACK_NAME', nil)
    custom_opts[:stack_name] = ENV['STACK_NAME']
  end
  if ENV.fetch('LOG_STDOUT', false)
    config.logger = Logger.new(STDOUT)
  end
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.log_level = (ENV['LOG_LEVEL'] || 'info').to_sym
  # activerecord logging is too verbose and will push us over our loggly limit
  active_record_logger = Logger.new(STDOUT)
  active_record_logger.level = Logger::INFO
  config.active_record.logger = active_record_logger
  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    custom_opts[:params] = event.payload[:params].except(*exceptions)
    custom_opts[:search] = event.payload[:searchkick_runtime] if event.payload[:searchkick_runtime].to_f > 0
    custom_opts
  end

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { :host => Figaro.env.default_host }
  config.action_mailer.asset_host = Figaro.env.default_host
  # ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_ADDRESS'],
    port: 25,
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: 'plain',
    enable_starttls_auto: false,
    openssl_verify_mode: 'none',
  }

  config.active_record.raise_in_transactional_callbacks = false
end
