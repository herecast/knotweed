# == Schema Information
#
# Table name: content_reports
#
#  id                       :bigint(8)        not null, primary key
#  content_id               :bigint(8)
#  report_date              :datetime
#  view_count               :integer          default(0)
#  banner_click_count       :integer          default(0)
#  comment_count            :bigint(8)
#  total_view_count         :bigint(8)
#  total_banner_click_count :bigint(8)
#  total_comment_count      :bigint(8)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class ContentReport < ActiveRecord::Base
  belongs_to :content

  def view_count_hash
    {
      report_date: report_date.to_s,
      view_count: view_count || 0
    }
  end

  def banner_click_hash
    {
      report_date: report_date.to_s,
      banner_click_count: banner_click_count || 0
    }
  end
end
