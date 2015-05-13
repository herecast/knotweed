class DetailedEventInstanceSerializer < EventInstanceSerializer

  attributes :event_instances, :content_id

  def event_instances
    object.event.event_instances.map do |inst|
      AbbreviatedEventInstanceSerializer.new(inst).serializable_hash
    end
  end

  def content_id
    object.event.content.id
  end

end
