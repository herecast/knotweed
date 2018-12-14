module Api
  module V3
    class CommentSerializer < ActiveModel::Serializer
      # this is a little tricky -- you would think this model serializes the Comment model.
      # BUT since the comment model does basically nothing, this actually serializes Content
      # (associated with comments) in the desired comment struture

      attributes :id, :content, :published_at, :parent_content_id,
                 :user_id, :user_name, :content_id, :user_image_url

      def id
        if object.channel.present?
          object.channel.id
        else
          object.id
        end
      end

      def content
        object.sanitized_content
      end

      def user_name
        object.created_by.try(:name)
      end

      def user_id
        object.created_by_id
      end

      def parent_content_id
        object.parent_id
      end

      def user_image_url
        object.created_by.try(:avatar).try(:url)
      end

      def content_id
        object.id
      end

      def published_at
        object.pubdate
      end
    end
  end
end
