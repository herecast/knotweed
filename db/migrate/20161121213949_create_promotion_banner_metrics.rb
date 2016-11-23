class CreatePromotionBannerMetrics < ActiveRecord::Migration
  def change
    create_table :promotion_banner_metrics do |t|
      t.references :promotion_banner, index: true
      t.string :event_type
      t.integer :content_id
      t.string :select_method
      t.float :select_score
      t.integer :user_id
      t.string :location
      t.string :page_url

      t.timestamps null: false
    end
  end
end
