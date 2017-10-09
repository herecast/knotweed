module SearchIndexing
  class CommentSerializer < ::ActiveModel::Serializer
      attributes :id, :title, :content, :published_at, :content_id, :parent_content_id

      has_one :created_by, serializer: SearchIndexing::CreatedBySerializer

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
  end
end
