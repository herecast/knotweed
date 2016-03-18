module Api
  module V3
    class PromotionBannerMetricsSerializer < ActiveModel::Serializer

      attributes :id, :title, :pubdate, :image_url, :redirect_url,
        :campaign_start, :campaign_end, :max_impressions, :impression_count,
        :click_count, :daily_impression_counts, :daily_click_counts

      def title; object.promotion.content.title; end

      def pubdate; object.promotion.content.pubdate; end

      def image_url; object.banner_image.url; end

      def daily_impression_counts
        scope = object.promotion_banner_reports.order('report_date ASC')
        if context.present? && context[:start_date].present?
          scope = scope.where('report_date >= ?', context[:start_date])
          if context[:end_date].present?
            scope = scope.where('report_date <= ?', context[:end_date])
          end
        end
        scope.map do |report|
          {
            report_date: report.report_date,
            impression_count: report.impression_count
          }
        end
      end

      def daily_click_counts
        scope = object.promotion_banner_reports.order('report_date ASC')
        if context.present? && context[:start_date].present?
          scope = scope.where('report_date >= ?', context[:start_date])
          if context[:end_date].present?
            scope = scope.where('report_date <= ?', context[:end_date])
          end
        end
        scope.map do |report|
          {
            report_date: report.report_date,
            click_count: report.click_count
          }
        end
      end

    end
  end
end
