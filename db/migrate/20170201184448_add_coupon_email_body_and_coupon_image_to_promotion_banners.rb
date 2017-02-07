class AddCouponEmailBodyAndCouponImageToPromotionBanners < ActiveRecord::Migration
  def change
    add_column :promotion_banners, :coupon_email_body, :text
    add_column :promotion_banners, :coupon_image, :string
  end
end
