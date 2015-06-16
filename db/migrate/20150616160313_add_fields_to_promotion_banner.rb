class AddFieldsToPromotionBanner < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :campaign_start, :datetime
    add_column :promotion_banners, :campaign_end, :datetime
    add_column :promotion_banners, :max_impressions, :integer
    add_column :promotion_banners, :impression_count, :integer, default: 0
    add_column :promotion_banners, :click_count, :integer, default: 0
  end
end
