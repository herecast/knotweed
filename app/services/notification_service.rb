# This module exists to create an api for sending email notifications
# without needing to know implementation details of how the notification is sent.

module NotificationService
  extend self

  def subscription_verification(subscription)
    ListservMailer.subscription_verification(subscription).deliver_later
  end

  def existing_subscription(subscription)
    ListservMailer.existing_subscription(subscription).deliver_later
  end

  def posting_verification(posting,  **extra_context)
    ListservMailer.posting_verification(posting, **extra_context).deliver_later
  end

  def subscriber_blacklisted(subscription)
    ListservMailer.subscriber_blacklisted(subscription).deliver_later
  end

  def sign_in_link(sign_in_token)
    UserMailer.sign_in_link(sign_in_token).deliver_later
  end
end
