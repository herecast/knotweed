# == Schema Information
#
# Table name: content_reports
#
#  id                       :integer          not null, primary key
#  content_id               :integer
#  report_date              :datetime
#  view_count               :integer          default(0)
#  banner_click_count       :integer          default(0)
#  comment_count            :integer
#  total_view_count         :integer
#  total_banner_click_count :integer
#  total_comment_count      :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

require 'spec_helper'

describe ContentReport, :type => :model do
  before { @content_report = FactoryGirl.build :content_report }
  subject { @content_report }
  it { is_expected.to be_valid }
end
