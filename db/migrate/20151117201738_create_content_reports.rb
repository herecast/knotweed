class CreateContentReports < ActiveRecord::Migration
  def change
    create_table :content_reports do |t|
      t.integer :content_id
      t.datetime :report_date
      t.integer :view_count
      t.integer :banner_click_count
      t.integer :comment_count
      t.integer :total_view_count
      t.integer :total_banner_click_count
      t.integer :total_comment_count

      t.timestamps
    end
  end
end
