require 'spec_helper'

RSpec.describe RecordPromotionBannerMetric do
  before do
    @promotion_banner = FactoryGirl.create :promotion_banner
  end 

  describe "::call" do
    context "with event_type: load" do
      subject { RecordPromotionBannerMetric.call('load', nil, @promotion_banner, Date.current.to_s) }
      
      it "reports load event" do
        expect{ subject }.to change{
          PromotionBannerMetric.where(event_type: 'load').count
        }.by 1
      end

      it "increases load count of promotion_banner" do
        expect{ subject }.to change{
          @promotion_banner.reload.load_count
        }.by 1
      end
    end

    context "with event_type: impression" do
      subject { RecordPromotionBannerMetric.call('impression', nil, @promotion_banner, Date.current.to_s,
        gtm_blocked: true
      ) }
      
      it "reports impression event" do
        expect{ subject }.to change{
          PromotionBannerMetric.where(event_type: 'impression').count
        }.by 1
      end

      it "increases impression count of promotion_banner" do
        expect{ subject }.to change{
          @promotion_banner.reload.impression_count
        }.by 1
      end

      it "increases daily impression count of promotion_banner" do
        expect{ subject }.to change{
          @promotion_banner.reload.daily_impression_count
        }.by 1
      end

      context "when gtm is blocked on front end" do
        it "records gtm_blocked as true" do
          subject
          expect(PromotionBannerMetric.last.gtm_blocked).to be true
        end
      end
    end

    context "with event_type: click" do
      subject { RecordPromotionBannerMetric.call('click', nil, @promotion_banner, Date.current.to_s) }
      
      it "reports click event" do
        expect{ subject }.to change{
          PromotionBannerMetric.where(event_type: 'click').count
        }.by 1
      end

      it "increases click count of promotion_banner" do
        expect{ subject }.to change{
          @promotion_banner.reload.click_count
        }.by 1
      end
    end

    context "when promotion banner does not have current report" do
      subject { RecordPromotionBannerMetric.call('load', nil, @promotion_banner, Date.current.to_s) }
      
      it "creates a promotion banner report" do
        expect{ subject }.to change{
          PromotionBannerReport.count
        }.by 1
        expect(PromotionBannerReport.last.load_count).to eq 1
      end
    end

    context "when promotion banner has current report" do
      before do
        @promotion_banner_report = FactoryGirl.create :promotion_banner_report,
          promotion_banner_id: @promotion_banner.id,
          report_date: Date.current
      end

      subject { RecordPromotionBannerMetric.call('click', nil, @promotion_banner, Date.current.to_s) }

      it "increments promotion banner report stats" do
        expect{ subject }.to change{
          @promotion_banner_report.reload.click_count
        }.by 1
      end
    end
  end
end