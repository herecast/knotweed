class MailchimpService::SubscriptionSerializer < ActiveModel::Serializer
  root false
  attributes :email_type, :status, :ip_signup, :timestamp_signup, :ip_opt,
    :timestamp_opt, :email_address, :status_if_new, :merge_fields

  def status
    if object.unsubscribed?
      'unsubscribed'
    elsif object.confirmed?
      'subscribed'
    end
  end

  def ip_signup
    object.confirm_ip
  end

  def timestamp_signup
    object.created_at
  end

  def ip_opt
    object.confirm_ip
  end

  def timestamp_opt
    object.confirmed_at
  end

  def email_address
    object.email
  end

  def status_if_new
    "subscribed"
  end

  def merge_fields
    {
      FNAME: object.subscriber_name.to_s.split(/\s+/).first,
      LNAME: object.subscriber_name.to_s.split(/\s+/).last
    }
  end
end
