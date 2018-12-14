module SearchIndexing
  class CommentSerializer < ::ActiveModel::Serializer
    attributes :id,
               :content,
               :content_id,
               :parent_content_id,
               :published_at,
               :title,
               :user_id,
               :user_image_url,
               :user_name

    def id
      if object.channel.present?
        object.channel.id
      else
        object.id
      end
    end

    def title
      object.sanitized_title
    end

    def content
      object.sanitized_content
    end

    def parent_content_id
      object.parent_id
    end

    def content_id
      object.id
    end

    def published_at
      object.pubdate
    end

    def user_id
      object.created_by_id
    end

    def user_name
      object.created_by.try :name
    end

    def user_image_url
      object.created_by.try :avatar_url
    end
  end
end
