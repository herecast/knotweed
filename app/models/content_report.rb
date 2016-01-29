# == Schema Information
#
# Table name: content_reports
#
#  id                       :integer          not null, primary key
#  content_id               :integer
#  report_date              :datetime
#  view_count               :integer
#  banner_click_count       :integer
#  comment_count            :integer
#  total_view_count         :integer
#  total_banner_click_count :integer
#  total_comment_count      :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class ContentReport < ActiveRecord::Base
  belongs_to :content

  attr_accessible :banner_click_count, :comment_count, :content_id, :report_date, 
    :total_banner_click_count, :total_comment_count, :total_view_count, :view_count
end
