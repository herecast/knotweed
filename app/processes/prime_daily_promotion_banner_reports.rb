class PrimeDailyPromotionBannerReports

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(current_date)
    @current_date = current_date.to_date
  end

  def call
    reset_daily_impression_counts
    create_reports_for_track_daily_metrics_promotion_banners
    update_active_promotions
  end

  private

    def reset_daily_impression_counts
      PromotionBanner.where("daily_impression_count > 0")
        .update_all("daily_impression_count = 0")
    end

    def create_reports_for_track_daily_metrics_promotion_banners
      PromotionBanner.where(track_daily_metrics: true).each do |promotion_banner|
        promotion_banner.find_or_create_daily_report(@current_date)
      end
    end

    def update_active_promotions
      PromotionBanner.all.each do |promo|
        promo.update_active_promotions
      end
    end

end