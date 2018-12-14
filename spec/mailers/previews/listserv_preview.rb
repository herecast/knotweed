# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/subscriptions
class ListservPreview < ActionMailer::Preview
  def subscription_verification
    ListservMailer.subscription_verification(Subscription.last)
  end

  def existing_subscription
    ListservMailer.existing_subscription(Subscription.last)
  end

  def subscriber_blacklisted
    ListservMailer.subscriber_blacklisted(Subscription.last)
  end
end
