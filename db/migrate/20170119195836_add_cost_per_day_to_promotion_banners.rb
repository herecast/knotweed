class AddCostPerDayToPromotionBanners < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :cost_per_day, :float
  end
end
