# frozen_string_literal: true

if Rails.env.production?
  # Disable warning logs so we don't fill up loggly
  Hashie.logger = Logger.new('/dev/null')
end
