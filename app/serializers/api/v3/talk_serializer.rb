module Api
  module V3
    class TalkSerializer < ActiveModel::Serializer

      attributes :id, :title, :user_count, :pageviews_count, :author_name,
        :author_image_url, :published_at, :view_count, :commenter_count, :comment_count, :parent_id

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

      # NOTE: this may change to created_by.name instead of authors,
      # although we won't have a "created_by" in content that is imported,
      # so most likely the answer is use created_by but fall back to authors.
      def author_name
        object.authors
      end

      def author_image_url
        # PENDING avatar implementation
      end

      def published_at
        object.pubdate
      end

      def view_count
        object.view_count
      end

      def commenter_count
        object.commenter_count
      end

      def comment_count
        object.comment_count
      end

      def parent_id
        if object.parent.present?
          object.parent.id
        end
      end
    end
  end
end
