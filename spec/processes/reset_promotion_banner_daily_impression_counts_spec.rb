require 'spec_helper'

RSpec.describe ResetPromotionBannerDailyImpressionCounts do

  describe "::call" do
    it "resets promotion_banners.daily_impression_counts" do
      promotion_banner = FactoryGirl.create :promotion_banner, daily_impression_count: 4
      ResetPromotionBannerDailyImpressionCounts.call
      expect(promotion_banner.reload.daily_impression_count).to eq 0
    end
  end
end