class AddAdServiceIdToPromotionBanners < ActiveRecord::Migration[5.1]
  def change
    add_column :promotion_banners, :ad_service_id, :string
    add_index :promotion_banners, :ad_service_id
  end
end
