# frozen_string_literal: true

module Api
  module V3
    class PromotionBannerMetricsSerializer < ActiveModel::Serializer
      attributes :id, :title, :pubdate, :image_url, :redirect_url,
                 :campaign_start, :campaign_end, :max_impressions, :impression_count,
                 :click_count, :daily_impression_counts, :daily_click_counts

      def title
        object.promotion.content.title
      end

      def pubdate
        object.promotion.content.pubdate
      end

      def image_url
        object.banner_image.url
      end

      def daily_impression_counts
        object.daily_counts(event_type: 'impression', start_date: context[:start_date], end_date: context[:end_date]).
          map do |report|
          {
            report_date: report.report_date,
            impression_count: report.daily_count
          }
        end
      end

      def daily_click_counts
        object.daily_counts(event_type: 'click', start_date: context[:start_date], end_date: context[:end_date]).
          map do |report|
          {
            report_date: report.report_date,
            click_count: report.daily_count
          }
        end
      end
    end
  end
end
