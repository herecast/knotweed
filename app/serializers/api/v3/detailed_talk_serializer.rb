module Api
  module V3
    class DetailedTalkSerializer < ActiveModel::Serializer

      attributes :id, :title, :content, :content_id, :image_url, :user_count,
        :pageviews_count, :author_name, :author_image_url, :published_at

      def title
        object.sanitized_title
      end

      def content
        object.sanitized_content
      end

      def content_id
        object.id
      end

      def id
        if object.channel.present?
          object.channel_id
        else
          object.id
        end
      end

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

      def user_count
        # PENDING
      end

      def pageviews_count
        # PENDING
      end

      def author_name
        if object.created_by.present?
          object.created_by.name
        else
          object.authors
        end
      end

      def author_image_url
        # PENDING
      end

      def published_at
        object.pubdate
      end

    end
  end
end
