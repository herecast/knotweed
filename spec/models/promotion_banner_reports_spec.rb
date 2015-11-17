require 'spec_helper'

describe PromotionBannerReports do
  before { @promotion_banner_report = FactoryGirl.create :promotion_banner_report }
  subject { @promotion_banner_report }
  it { should be_valid }
end
