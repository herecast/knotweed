# Preview all emails at http://localhost:3000/rails/mailers/subscriptions
class ListservPreview < ActionMailer::Preview
  def subscription_verification
    ListservMailer.subscription_verification(Subscription.last)
  end

  def subscription_confirmation
    ListservMailer.subscription_confirmation(Subscription.last)
  end

  def existing_subscription
    ListservMailer.existing_subscription(Subscription.last)
  end

  def posting_verification
    ListservMailer.posting_verification(ListservContent.last)
  end
end
