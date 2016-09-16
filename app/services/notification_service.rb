# This module exists to create an api for sending email notifications
# without needing to know implementation details of how the notification is sent.

module NotificationService
  extend self

  def subscription_confirmation(subscription)
    ListservMailer.subscription_confirmation(subscription).deliver_later
  end

  def subscription_verification(subscription)
    ListservMailer.subscription_verification(subscription).deliver_later
  end

  def existing_subscription(subscription)
    ListservMailer.existing_subscription(subscription).deliver_later
  end

  def posting_confirmation(posting, temp_password = nil)
    ListservMailer.posting_confirmation(posting, temp_password).deliver_later
  end

  def posting_verification(posting)
    ListservMailer.posting_verification(posting).deliver_later
  end
end