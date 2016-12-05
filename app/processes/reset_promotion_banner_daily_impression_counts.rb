class ResetPromotionBannerDailyImpressionCounts

  def self.call
    PromotionBanner.where("daily_impression_count > 0")
      .update_all("daily_impression_count = 0")
  end
end