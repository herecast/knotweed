module Api
  module V3
    # note, this serializer actually takes content objects, not market post objects
    class MarketPostSerializer < ActiveModel::Serializer

      attributes :id, :title, :published_at, :image_url, :content_id

      def content_id
        object.id
      end

      def title
        object.sanitized_title
      end

      def published_at
        object.pubdate
      end

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

    end
  end
end
