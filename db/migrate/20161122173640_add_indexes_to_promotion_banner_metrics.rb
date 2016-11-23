class AddIndexesToPromotionBannerMetrics < ActiveRecord::Migration
  def change
    add_index :promotion_banner_metrics, :event_type
    add_index :promotion_banner_metrics, :created_at
  end
end
