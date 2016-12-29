class AddPromotionTypeToPromotionBanners < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :promotion_type, :string
  end
end
