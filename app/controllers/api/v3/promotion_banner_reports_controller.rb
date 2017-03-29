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
        elsif params[:status] == "active"
          @promotion_banners = @promotion_banners.active
        end

        render json: @promotion_banners, context: { start_date: start_date, end_date: end_date },
          each_serializer: PromotionBannerReportSerializer
      end

      def show_daily_report
        date = Chronic.parse(params[:report_date])
        @promotion_banners = PromotionBanner.includes(promotion: :content)
                                            .includes(:promotion_banner_reports)
                                            .where("date_trunc('day', promotion_banner_reports.report_date) = ?", date.strftime('%Y-%m-%d'))
                                            .active(date.to_date)
                                            .paid
        report = []
        @promotion_banners.each do |pb|
          report << {
            promotion_id:     pb.promotion.id,
            title:            pb.promotion.content.title,
            type:            "Cost type: #{pb.cost_per_day ? "Per day" : "Per impression"}, #{pb.cost_per_day || pb.cost_per_impression}",
            impression_count: pb.promotion_banner_reports.first.try(:impression_count),
            revenue:          pb.promotion_banner_reports.first.try(:daily_revenue)
          }
        end
        render json: { report: report }
      end

    end
  end
end
