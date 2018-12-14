# Creates a subscription object related to listserv, and triggers verification email
# If subscription already exists, then resubscribes (unsets unsubscribed_at_
class SubscribeToListserv
  # @param [Listserv] Listserv to subscribe to
  # @param [Hash] including email key
  # @return [Subscription]
  def self.call(listserv, attrs = {})
    sub = Subscription.find_or_initialize_by({
                                               listserv: listserv,
                                               email: attrs[:email]
                                             });
    sub.attributes = attrs
    sub.unsubscribed_at = nil

    if sub.persisted? && sub.confirmed?
      sub.save!
      NotificationService.existing_subscription(sub)
    else
      sub.save!
      NotificationService.subscription_verification(sub)
    end

    return sub
  end
end
