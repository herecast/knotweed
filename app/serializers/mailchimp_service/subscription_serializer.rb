# frozen_string_literal: true

class MailchimpService::SubscriptionSerializer < ActiveModel::Serializer
  root false
  attributes :email_type,
    :status,
    :ip_signup,
    :timestamp_signup,
    :ip_opt,
    :timestamp_opt,
    :email_address,
    :status_if_new,
    :location,
    :merge_fields,
    :interests

  def status
    object.confirmed? ? 'subscribed' : 'pending'
  end

  def ip_signup
    object.confirm_ip
  end

  def timestamp_signup
    mc_formatted_time(object.created_at)
  end

  def ip_opt
    object.confirm_ip
  end

  def timestamp_opt
    mc_formatted_time(object.confirmed_at)
  end

  def email_address
    object.email
  end

  def status_if_new
    status
  end

  def location
    {
      latitude: object.user.location.latitude,
      longitude: object.user.location.longitude
    }
  end

  def merge_fields
    {
      FNAME: object.subscriber_name.to_s.split(/\s+/).first.to_s,
      LNAME: object.subscriber_name.to_s.split(/\s+/).last.to_s
    }.tap do |h|
      if object.user&.location
        h[:ZIP] = object.user.location.zip if object.user.location.zip?
        h[:CITY] = object.user.location.city
        h[:STATE] = object.user.location.state
      end
      h
    end
  end

  def interests
    {
      MailchimpService.find_or_create_digest(
        object.listserv.mc_list_id,
        object.listserv.mc_group_name
      )[:id] => !object.unsubscribed?
    }
  end

  def filter(keys)
    keys -= %i[ip_signup ip_opt timestamp_opt] unless object.confirmed?

    unless object.user&.location &&
           object.user.location.geocoded?
      keys -= [:location]
    end

    keys
  end

  private

    def mc_formatted_time(datetime)
      if datetime.present?
        datetime.strftime('%Y-%m-%d %H:%M:%S')
      end
    end

end
