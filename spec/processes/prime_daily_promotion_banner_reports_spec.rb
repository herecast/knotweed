require 'spec_helper'

RSpec.describe PrimeDailyPromotionBannerReports do

  describe "::call" do
    let!(:banner) { FactoryGirl.create :promotion_banner, daily_impression_count: 4 }

    subject { PrimeDailyPromotionBannerReports.call(Date.current) }

    it "resets promotion_banners.daily_impression_counts" do
      subject
      expect(banner.reload.daily_impression_count).to eq 0
    end

    describe 'for a currently active promotion' do
      let!(:active_banner) { FactoryGirl.create :promotion_banner, :active }

      it "creates PromotionBannerReport for promotion_banners currently active" do
        expect{ subject }.to change{
          active_banner.promotion_banner_reports.count
        }.by(1)
      end
    end

    describe 'for an inactive promotion' do
      let!(:inactive_banner) { FactoryGirl.create :promotion_banner, :inactive }

      it 'does not create a PromotionBannerReport' do
        expect{ subject }.to_not change{
          inactive_banner.promotion_banner_reports.count
        }
      end
    end
  end
end
