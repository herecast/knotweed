module Api
  module V3
    class RelatedPromotionSerializer < ActiveModel::Serializer
      attributes :id, :banner_id, :image_url, :redirect_url, :organization_name, :promotion_id, :title

      def banner_id
        object.id
      end

      def organization_name
        object.promotion.organization.try(:name)
      end

      def promotion_id
        object.promotion.id
      end

      def image_url
        object.banner_image.url
      end

      def title
        object.promotion.content.try(:title)
      end
    end
  end
end
