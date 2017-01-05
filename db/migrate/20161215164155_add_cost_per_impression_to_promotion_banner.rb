class AddCostPerImpressionToPromotionBanner < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :cost_per_impression, :float
  end
end
