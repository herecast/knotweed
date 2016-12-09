require 'spec_helper'

RSpec.describe PrimeDailyPromotionBannerReports do

  describe "::call" do
    before do
      @promotion_banner_one = FactoryGirl.create :promotion_banner, daily_impression_count: 4
      @promotion_banner_two = FactoryGirl.create :promotion_banner, track_daily_metrics: true
    end

    subject { PrimeDailyPromotionBannerReports.call(Date.current) }

    it "resets promotion_banners.daily_impression_counts" do
      subject
      expect(@promotion_banner_one.reload.daily_impression_count).to eq 0
    end

    it "creates PromotionBannerReport for promotion_banners with track_daily_metrics=true" do
      expect{ subject }.to change{
        @promotion_banner_two.reload.promotion_banner_reports.count
      }.by(1).and change{
        @promotion_banner_one.reload.promotion_banner_reports.count
      }.by 0
    end
  end
end