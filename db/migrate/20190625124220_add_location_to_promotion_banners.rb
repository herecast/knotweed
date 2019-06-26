class AddLocationToPromotionBanners < ActiveRecord::Migration[5.1]
  def change
    add_reference :promotion_banners, :location, foreign_key: true, index: true
  end
end
