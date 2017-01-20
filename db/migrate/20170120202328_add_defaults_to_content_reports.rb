class AddDefaultsToContentReports < ActiveRecord::Migration
  def change
    change_column :content_reports, :view_count, :integer, default: 0
    change_column :content_reports, :banner_click_count, :integer, default: 0
  end
end
