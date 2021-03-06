# frozen_string_literal: true

class UnsubscribeSubscription
  def self.call(*args)
    new(*args).call
  end

  def initialize(subscription)
    @subscription = subscription
  end

  def call
    unless @subscription.unsubscribed?
      @subscription.update! unsubscribed_at: Time.current

      if @subscription.listserv.mc_sync?
        BackgroundJob.perform_later('MailchimpService', 'unsubscribe', @subscription)
      end
    end
  end
end
