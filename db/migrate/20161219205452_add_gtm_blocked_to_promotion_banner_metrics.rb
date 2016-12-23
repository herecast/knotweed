class AddGtmBlockedToPromotionBannerMetrics < ActiveRecord::Migration
  def change
    add_column :promotion_banner_metrics, :gtm_blocked, :boolean
  end
end
