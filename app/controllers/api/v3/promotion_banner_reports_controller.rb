module Api
  module V3
    class PromotionBannerReportsController < ApiController

      def index
        query = "SELECT p.id as \"promotion_id\", c.title, p.paid, date_trunc('day', pbr.report_date) AS \"report_date\",
          pbr.impression_count as \"daily_impression_count\", pbr.click_count as \"daily_click_count\",
          (
            SELECT SUM(impression_count) FROM promotion_banner_reports WHERE promotion_banner_id = pb.id
          ) as total_impression_count,
          (
            SELECT SUM(click_count) FROM promotion_banner_reports WHERE promotion_banner_id = pb.id
          ) as total_click_count,
          pb.campaign_start, pb.campaign_end,
          pb.max_impressions, p.content_id, pbr.promotion_banner_id
          FROM promotion_banner_reports pbr
          INNER JOIN promotion_banners pb ON pbr.promotion_banner_id = pb.id
          INNER JOIN promotions p ON p.promotable_type = 'PromotionBanner' AND p.promotable_id = pb.id
          INNER JOIN contents c ON p.content_id = c.id
          WHERE date_trunc('day', pbr.report_date) < CURRENT_DATE OR pb.track_daily_metrics = true
          ORDER BY DATE(report_date) DESC, campaign_start DESC, p.id DESC;"
        @promotion_banner_reports = ActiveRecord::Base.connection.execute(query)

        render json: { promotion_banner_reports: @promotion_banner_reports }
      end

    end
  end
end
