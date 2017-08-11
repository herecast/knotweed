module Api
  module V3
    class PromotionBannerSerializer < ActiveModel::Serializer

      attributes :id, :title, :pubdate, :image_url, :redirect_url,
        :campaign_start, :campaign_end, :max_impressions, :impression_count,
        :click_count, :content_type, :description

      def id; object.id; end

      def title; object.promotion.content.title; end

      def pubdate; object.promotion.content.pubdate; end

      def image_url; object.banner_image.url; end

      def content_type; 'promotion_banner'; end

      def impression_count; object.impression_count; end

      def click_count; object.click_count; end

      def description
        object.promotion.description
      end

    end
  end
end
