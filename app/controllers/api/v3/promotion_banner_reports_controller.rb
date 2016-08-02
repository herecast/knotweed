module Api
  module V3
    class PromotionBannerReportsController < ApiController

      def index
        query = "SELECT p.id as \"promotion_id\", c.title, p.paid, (pbr.report_date - INTERVAL '5' HOUR) AS \"report_date\",
          pbr.impression_count as \"daily_impression_count\", pbr.click_count as \"daily_click_count\",
          pbr.total_impression_count, pbr.total_click_count, pb.campaign_start, pb.campaign_end,
          pb.max_impressions, p.content_id, pbr.promotion_banner_id
          FROM promotion_banner_reports pbr
          INNER JOIN promotion_banners pb ON pbr.promotion_banner_id = pb.id
          INNER JOIN promotions p ON p.promotable_type = 'PromotionBanner' AND p.promotable_id = pb.id
          INNER JOIN contents c ON p.content_id = c.id
          ORDER BY report_date DESC, p.id DESC;"
        @promotion_banner_reports = ActiveRecord::Base.connection.execute(query)

        render json: { promotion_banner_reports: @promotion_banner_reports }
      end

    end
  end
end