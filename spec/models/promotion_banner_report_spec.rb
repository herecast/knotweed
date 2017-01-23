# == Schema Information
#
# Table name: promotion_banner_reports
#
#  id                     :integer          not null, primary key
#  promotion_banner_id    :integer
#  report_date            :datetime
#  impression_count       :integer
#  click_count            :integer
#  total_impression_count :integer
#  total_click_count      :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  load_count             :integer
#

require 'spec_helper'

describe PromotionBannerReport, :type => :model do
  before { @promotion_banner_report = FactoryGirl.build :promotion_banner_report }
  subject { @promotion_banner_report }
  it { is_expected.to be_valid }
end
