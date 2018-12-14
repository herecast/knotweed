class ApplicationJob < ActiveJob::Base
  queue_as :default

  def self.perform_later_if_redis_available(*args)
    begin
      self.perform_later(*args)
    rescue Redis::CannotConnectError
      logger.debug('Failed to connect to Redis to queue job')
    end
  end
end
