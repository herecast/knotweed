class EventSerializer < ActiveModel::Serializer
  attributes :cost, :contact_phone, :contact_email, :title, :cost_type, :content,
    :image_url, :social_enabled, :id,
    :venue_name, :venue_address, :venue_locate_name, :venue_url,
    :venue_city, :venue_state, :venue_id, :venue_latitude, :venue_longitude,
    :venue_locate_name, :venue_zip,
    :event_instances, :event_url

  # this is funky but without it, active model serializer tries to use the URL helper
  # event_url instead of the attribute.
  def event_url
    object.event_url
  end

  def title
    object.content.title
  end

  def content
    object.content.sanitized_content
  end

  def image_url
    if object.content.images.present?
      object.content.images[0].image.url
    end
  end

  def event_instances
    object.event_instances.map do |inst|
      AbbreviatedEventInstanceSerializer.new(inst).serializable_hash
    end
  end

  def venue_name
    object.venue.try(:name)
  end
  
  def venue_address
    object.venue.try(:address)
  end

  def venue_city
    object.venue.try(:city)
  end

  def venue_state
    object.venue.try(:state)
  end

  def venue_zip
    object.venue.try(:zip)
  end

  def venue_id
    object.venue.try(:id)
  end

  def venue_latitude
    object.venue.try(:latitude)
  end

  def venue_longitude
    object.venue.try(:longitude)
  end

  def venue_locate_name
    object.venue.try(:geocoding_address)
  end

  def venue_url
    object.venue.try(:venue_url)
  end

end
