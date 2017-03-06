class AddSalesAgentToPromotionBanners < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :sales_agent, :string
  end
end
