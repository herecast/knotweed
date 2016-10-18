class MailchimpService::SubscriptionSerializer < ActiveModel::Serializer
  root false
  attributes :email_type, :status, :ip_signup, :timestamp_signup, :ip_opt,
    :timestamp_opt, :email_address, :status_if_new, :location,:merge_fields,
    :interests

  def status
    object.confirmed? ? 'subscribed' : 'pending'
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
    status
  end

  def location
    {
      latitude: object.user.location.lat,
      longitude: object.user.location.long
    }
  end

  def merge_fields
    {
      FNAME: object.subscriber_name.to_s.split(/\s+/).first,
      LNAME: object.subscriber_name.to_s.split(/\s+/).last
    }.tap do |h|
      if object.user && object.user.location
        h[:ZIP] = object.user.location.zip
        h[:CITY] = object.user.location.city
        h[:STATE] = object.user.location.state
      end
      h
    end
  end

  def interests
    return {
      MailchimpService.find_or_create_digest(
        object.listserv.mc_list_id,
        object.listserv.mc_group_name
      )[:id] => !object.unsubscribed?
    }
  end

  def filter(keys)
    unless object.confirmed?
      keys = keys - [:ip_signup, :ip_opt, :timestamp_opt]
    end

    unless (object.user && object.user.location)
      keys  = keys - [:location]
    end

    keys
  end
end
