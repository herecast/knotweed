# A service object responsible for confirming the subscription and notifying the subscriber.
# It will unset unsubscribed_at if present (resubscribing)
#
class ConfirmSubscriptionAndNotify

  # @param [Subscription] - instance to confirm.
  # @param [String] - ip address used to confirm
  def self.call(*args)
    self.new(*args).call
  end

  def initialize(subscription, confirm_ip)
    @subscription = subscription
    @confirm_ip = confirm_ip
  end

  def call
    previously_confirmed = @subscription.confirmed?
    previously_unsubscribed = @subscription.unsubscribed?

    ConfirmSubscription.call(@subscription, @confirm_ip)

    if previously_unsubscribed or (not previously_confirmed)
      NotificationService.subscription_confirmation(@subscription)
    end
  end
end
