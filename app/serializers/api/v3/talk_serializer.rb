module Api
  module V3
    class TalkSerializer < ActiveModel::Serializer

      attributes :id, :title, :user_count, :pageviews_count, :author_name,
        :author_image_url, :published_at

      def title
        object.sanitized_title
      end

      def user_count
        # PENDING
        0
      end

      def pageviews_count
        # PENDING
        0
      end

      # NOTE: we won't have a "created_by" in content that is imported,
      # use created_by when availble else fall back to authors.
      def author_name
        if object.created_by.present?
          object.created_by.name
        else
          object.authors
        end
      end

      def author_image_url
        # PENDING avatar implementation
      end

      def published_at
        object.pubdate
      end

    end
  end
end
