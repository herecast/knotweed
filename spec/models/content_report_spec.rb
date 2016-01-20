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

require 'spec_helper'

describe ContentReport do
  before { @content_report = FactoryGirl.build :content_report }
  subject { @content_report }
  it { should be_valid }
end
