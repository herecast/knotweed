class CreateContentPromotionBannerImpressions < ActiveRecord::Migration
  def change
    create_table :content_promotion_banner_impressions do |t|
      t.integer :content_id
      t.integer :promotion_banner_id
      t.integer :display_count, default: 1

      t.timestamps
    end

    add_index :content_promotion_banner_impressions, [:content_id, :promotion_banner_id], 
      unique: true, name: 'content_promotion_banner_impression'
  end
end
