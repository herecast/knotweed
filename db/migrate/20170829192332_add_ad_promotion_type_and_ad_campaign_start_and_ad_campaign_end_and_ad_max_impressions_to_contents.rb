class AddAdPromotionTypeAndAdCampaignStartAndAdCampaignEndAndAdMaxImpressionsToContents < ActiveRecord::Migration
  def change
    add_column :contents, :ad_promotion_type, :string
    add_column :contents, :ad_campaign_start, :datetime
    add_column :contents, :ad_campaign_end, :datetime
    add_column :contents, :ad_max_impressions, :integer
  end
end
