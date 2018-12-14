# frozen_string_literal: true

# A service object responsible for confirming the subscription.
# It will unset unsubscribed_at if present (resubscribing)
#
class ConfirmSubscription
  # @param [Subscription] - instance to confirm.
  # @param [String] - ip address used to confirm
  def self.call(*args)
    new(*args).call
  end

  def initialize(subscription, confirm_ip)
    @subscription = subscription
    @confirm_ip = confirm_ip
  end

  def call
    if !@subscription.confirmed?
      @subscription.confirm_ip = @confirm_ip
      @subscription.confirmed_at ||= Time.current
      @subscription.unsubscribed_at = nil
      @subscription.save!
      sync_with_mc
    elsif @subscription.unsubscribed?
      @subscription.update! unsubscribed_at: nil
      sync_with_mc
    end
  end

  private

  def sync_with_mc
    if @subscription.listserv.mc_sync?
      BackgroundJob.perform_later('MailchimpService', 'subscribe', @subscription)
    end
  end
end
