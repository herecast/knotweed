class ContentReports < ActiveRecord::Base
  attr_accessible :banner_click_count, :comment_count, :content_id, :report_date, :total_banner_click_count, :total_comment_count, :total_view_count, :view_count
end
