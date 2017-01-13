module Api
  module V3
    class PromotionBannerReportsController < ApiController

      def index
        start_date = Chronic.parse(params[:start_date]) || 14.days.ago
        end_date = Chronic.parse(params[:end_date]) || Date.today.end_of_day
        # only retreive banners with reports in the time frame
        @promotion_banners = PromotionBanner
          .where("id in (select promotion_banner_id from promotion_banner_reports where report_date >= ? and report_date <= ?)",
                 start_date, end_date)
          .includes([{promotion: [:content, :organization]}, :promotion_banner_reports])
          .order(id: :desc)

        if params[:status] == "inactive"
          @promotion_banners = @promotion_banners
            .where("campaign_end < ? or campaign_start > ?", Time.current, Time.current)
        else
          @promotion_banners = @promotion_banners.active
        end

        render json: @promotion_banners, context: { start_date: start_date, end_date: end_date },
          each_serializer: PromotionBannerReportSerializer
      end

    end
  end
end
