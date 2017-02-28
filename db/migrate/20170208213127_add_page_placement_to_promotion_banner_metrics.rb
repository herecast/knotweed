class AddPagePlacementToPromotionBannerMetrics < ActiveRecord::Migration
  def change
    add_column :promotion_banner_metrics, :page_placement, :string
  end
end
