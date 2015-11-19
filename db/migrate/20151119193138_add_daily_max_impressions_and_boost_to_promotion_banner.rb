class AddDailyMaxImpressionsAndBoostToPromotionBanner < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :daily_max_impressions, :integer
    add_column :promotion_banners, :boost, :boolean, default: false
  end
end
