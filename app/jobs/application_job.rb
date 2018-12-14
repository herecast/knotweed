# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  queue_as :default

  def self.perform_later_if_redis_available(*args)
    perform_later(*args)
  rescue Redis::CannotConnectError
    logger.debug('Failed to connect to Redis to queue job')
  end
end
