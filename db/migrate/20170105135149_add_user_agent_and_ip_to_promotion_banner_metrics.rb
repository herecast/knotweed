class AddUserAgentAndIpToPromotionBannerMetrics < ActiveRecord::Migration
  def change
    add_column :promotion_banner_metrics, :user_agent, :string
    add_column :promotion_banner_metrics, :user_ip, :string
  end
end
