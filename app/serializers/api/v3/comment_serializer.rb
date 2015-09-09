module Api
  module V3
    class CommentSerializer < ActiveModel::Serializer

      # this is a little tricky -- you would think this model serializes the Comment model.
      # BUT since the comment model does basically nothing, this actually serializes Content
      # (associated with comments) in the desired comment struture

      attributes :id, :content, :pubdate, :parent_content_id,
        :user_id, :user_name
        #TODO user_image_url

      def id
        object.channel.id
      end

      def content
        object.sanitized_content
      end

      def user_name
        object.created_by.try(:name)
      end

      def user_id
        object.created_by.try(:id)
      end
      
      def parent_content_id
        object.parent_id
      end
      
      def pubdate
        object.pubdate
      end

    end
  end
end
