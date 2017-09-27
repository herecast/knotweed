class AddContentIdIndexOnPromotionBannerMetrics < ActiveRecord::Migration
  def change
    add_index :promotion_banner_metrics, :content_id
  end
end
