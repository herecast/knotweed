module Api
  module V3
    # note, this serializer actually takes content objects, not market post objects
    class MarketPostSerializer < ActiveModel::Serializer

      attributes :id, :title, :published_at, :image_url, :content_id, :my_town_only,
        :cost

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
        # NOTE: this works because the primary_image method returns images.first
        # if no primary image exists (or nil if no image exists at all)
        object.primary_image.try(:image).try(:url)
      end

      def cost
        object.try(:channel).try(:cost)
      end

    end
  end
end
