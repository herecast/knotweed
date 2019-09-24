require 'spec_helper'

RSpec.describe Promotions::CalculateAdRevenue do
  describe "::call" do
    let(:campaign) do
      FactoryGirl.create :content, :campaign, ad_campaign_start: 1.week.ago, 
                         ad_campaign_end: 1.week.from_now, ad_invoiced_amount: 100
    end

    subject { Promotions::CalculateAdRevenue.call(campaign, start_date, end_date) }

    context 'with no overlap with the ad campaign' do
      let(:start_date) { campaign.ad_campaign_end + 1.day }
      let(:end_date) { campaign.ad_campaign_end + 5.days }

      it 'should return 0' do
        expect(subject).to eq 0
      end
    end

    context 'with partial overlap with the ad campaign' do
      let(:start_date) { campaign.ad_campaign_end - 2.days }
      let(:end_date) { campaign.ad_campaign_end + 2.days }

      it 'should return the appropriate portion of the ad campaign revenue' do
        rev_per_day = campaign.ad_invoiced_amount / ((campaign.ad_campaign_end - campaign.ad_campaign_start).to_i + 1)
        expect(subject).to eq rev_per_day*3
      end
    end

    context 'with full overlap with the ad campaign' do
      let(:start_date) { campaign.ad_campaign_start }
      let(:end_date) { campaign.ad_campaign_end }

      it 'should return the full ad_invoiced_amount' do
        expect(subject).to eq campaign.ad_invoiced_amount
      end
    end
  end
end
