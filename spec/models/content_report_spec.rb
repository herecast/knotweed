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

require 'spec_helper'

describe ContentReport, :type => :model do
  before { @content_report = FactoryGirl.build :content_report }
  subject { @content_report }
  it { is_expected.to be_valid }
end
