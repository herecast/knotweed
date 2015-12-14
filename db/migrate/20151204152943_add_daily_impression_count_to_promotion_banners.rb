class AddDailyImpressionCountToPromotionBanners < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :daily_impression_count, :integer, default: 0
  end
end
