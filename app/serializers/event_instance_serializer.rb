class EventInstanceSerializer < ActiveModel::Serializer

  attributes :id, :subtitle, :starts_at, :ends_at

  has_one :event

  def filter(keys)
    unless serialization_options.has_key? :include_event and serialization_options[:include_event] == true
      keys.delete :event
    end
    keys
  end

  def subtitle
    object.subtitle_override
  end

  def starts_at
    object.start_date
  end
  
  def ends_at
    object.end_date
  end

end

