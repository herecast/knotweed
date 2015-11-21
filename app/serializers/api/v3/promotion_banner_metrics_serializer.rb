module Api
  module V3
    class PromotionBannerMetricsSerializer < ActiveModel::Serializer

      attributes :id, :title, :pubdate, :image_url, :redirect_url,
        :campaign_start, :campaign_end, :max_impressions, :impression_count,
        :click_count, :daily_impression_counts, :daily_click_counts

      def title; object.promotion.content.title; end

      def pubdate; object.promotion.content.pubdate; end

      def image_url; object.banner_image.url; end

      # PENDING REPORTS CODE
      def daily_impression_counts; []; end
      def daily_click_counts; []; end

    end
  end
end
