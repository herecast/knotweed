class CreatePromotionBannerReports < ActiveRecord::Migration
  def change
    create_table :promotion_banner_reports do |t|
      t.integer :promotion_banner_id
      t.datetime :report_date
      t.integer :impression_count
      t.integer :click_count
      t.integer :total_impression_count
      t.integer :total_click_count

      t.timestamps
    end
  end
end
