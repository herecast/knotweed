class PrimeDailyPromotionBannerReports

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(current_date, is_prod)
    @current_date = current_date.to_date
    @is_prod      = is_prod
  end

  def call
    reset_daily_impression_counts
    create_reports_for_current_promotion_banners
    update_active_promotions
    notify_admin_team_of_sunsetting_ads if @is_prod
  end

  private

    def reset_daily_impression_counts
      PromotionBanner.where("daily_impression_count > 0")
        .update_all("daily_impression_count = 0")
    end

    def create_reports_for_current_promotion_banners
      PromotionBanner.active(@current_date).each do |promotion_banner|
        promotion_banner.find_or_create_daily_report(@current_date)
      end
    end

    def update_active_promotions
      PromotionBanner.all.each do |promo|
        promo.update_active_promotions
      end
    end

    def notify_admin_team_of_sunsetting_ads
      PromotionBanner.sunsetting.each do |promotion_banner|
        AdMailer.ad_sunsetting(promotion_banner).deliver_now
      end
    end

end
