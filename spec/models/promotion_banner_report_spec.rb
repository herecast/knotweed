require 'spec_helper'

describe PromotionBannerReport do
  before { @promotion_banner_report = FactoryGirl.build :promotion_banner_report }
  subject { @promotion_banner_report }
  it { should be_valid }
end
