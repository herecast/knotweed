class ChangeCampaignDateFieldsOnPromotionBanner < ActiveRecord::Migration
  def change
    change_column :promotion_banners, :campaign_start, :date
    change_column :promotion_banners, :campaign_end, :date
  end
end
