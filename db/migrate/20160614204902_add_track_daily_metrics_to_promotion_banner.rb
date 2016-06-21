class AddTrackDailyMetricsToPromotionBanner < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :track_daily_metrics, :boolean
  end
end
