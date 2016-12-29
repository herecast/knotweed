class RemoveTrackDailyMetricsFromPromotionBanners < ActiveRecord::Migration
  def change
    remove_column :promotion_banners, :track_daily_metrics, :boolean
  end
end
