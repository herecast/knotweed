class SimilarContentSerializer < ActiveModel::Serializer

  attributes :content_id, :title, :author, :pubdate, :content,
    :event_instance_id

  def content
    object.raw_content
  end

  def content_id
    object.id
  end

  def author
    object.authors
  end

  def event_instance_id
    if object.channel_type == 'Event'
      object.channel.event_instances.first.id
    end
  end

end
