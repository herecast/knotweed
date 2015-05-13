class EventSerializer < ActiveModel::Serializer

  attributes :id, :content, :image_url, :cost, :venue_name, :venue_address,
    :venue_city, :venue_state, :venue_id, :venue_latitude, :venue_longitude,
    :venue_locate_name, :venue_url, :contact_phone, :contact_email,
    :title, :subtitle

  has_many :event_instances

  def filter(keys)
    unless serialization_options.has_key? :include_instances and serialization_options[:include_instances] == true
      keys.delete :event_instances
    end
    keys
  end

  def content
    object.content.raw_content
  end

  def image_url
    object.content.images.first.image.url if object.content.images.present?
  end

  def venue_name
    object.venue.try(:name)
  end
  
  def venue_address
    object.venue.try(:address)
  end

  def venue_city
    #object.venue.city
  end

  def venue_state
    #object.venue.state
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
  end

  def venue_url
    object.venue.try(:venue_url)
  end

  def title
    object.content.title
  end

  def subtitle
    object.content.subtitle
  end

end
