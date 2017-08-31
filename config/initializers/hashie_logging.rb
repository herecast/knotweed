if Rails.env.production?
  # Disable warning logs so we don't fill up loggly
  Hashie.logger = Logger.new('/dev/null')
end
