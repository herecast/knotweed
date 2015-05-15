class CommentSerializer < ActiveModel::Serializer

  # this is a little tricky -- you would think this model serializes the Comment model.
  # BUT since the comment model does basically nothing, this actually serializes Content
  # (associated with comments) in the desired comment struture

  attributes :id, :content, :comments, :event_id

  def id
    object.channel.id
  end

  def content
    object.raw_content
  end

  def event_id
    serialization_options[:event_id] if serialization_options.has_key? :event_id
  end

  def comments
    if object.children.present?
      object.children.map do |child|
        # only include Comments in thread
        if child.channel.is_a? Comment
          options = { event_id: self.event_id }
          CommentSerializer.new(child, options).serializable_hash
        end
      end
    end
  end

end
