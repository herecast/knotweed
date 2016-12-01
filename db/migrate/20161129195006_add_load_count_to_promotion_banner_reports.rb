class AddLoadCountToPromotionBannerReports < ActiveRecord::Migration
  def change
    add_column :promotion_banner_reports, :load_count, :integer
    add_index :promotion_banner_reports, :promotion_banner_id
    add_index :promotion_banner_reports, :report_date
  end
end
