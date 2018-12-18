# frozen_string_literal: true

module Api
  module V3
    class PromotionCouponSerializer < ActiveModel::Serializer
      attributes :id, :promotion_id, :image_url, :promotion_type, :title, :message

      def promotion_id
        object.promotion.id
      end

      def image_url
        object.coupon_image.url
      end

      def title
        object.promotion.content.try(:title)
      end

      def message
        object.coupon_email_body
      end
    end
  end
end
