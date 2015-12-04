class AddSelectMethodToContentPromotionBannerImpressions < ActiveRecord::Migration
  def change
    add_column :content_promotion_banner_impressions, :select_method, :string
    add_column :content_promotion_banner_impressions, :select_score, :float
  end
end
