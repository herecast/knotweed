require 'spec_helper'

RSpec.describe Promotions::GatherMetrics do
  describe "::call" do
    context "when promotion type is Digest" do
      before do
        @opens = 50
        @clicks = 10
        promotable = FactoryGirl.create :promotion_banner,
          digest_opens: @opens,
          digest_clicks: @clicks
        @promotion = FactoryGirl.create :promotion,
          promotable: promotable
        @digest_campaign = FactoryGirl.create :content, :campaign,
          ad_promotion_type: 'Digest',
          promotions: [@promotion]
      end

      subject { Promotions::GatherMetrics.call(@digest_campaign) }

      it "returns digest metrics" do
        metrics = {
          id: @promotion.id,
          impression_count: @opens,
          click_count: @clicks
        }
        expect(subject).to eq [metrics]
      end
    end

    context "when campaign is ROS, Targeted or Sponsored" do
      before do
        @campaign = FactoryGirl.create :content, :campaign,
          ad_promotion_type: 'ROS'
        @max = 50
        @clicks = 12
        promotable = FactoryGirl.create :promotion_banner,
          daily_max_impressions: @max,
          campaign_start: 5.days.ago,
          campaign_end: 2.days.ago,
          click_count: @clicks,
          impression_count: 1_000_000
        @difference = (promotable.campaign_end - promotable.campaign_start).to_i + 1
        @promotion = FactoryGirl.create :promotion,
          promotable: promotable
        @campaign.promotions << @promotion
      end

      subject { Promotions::GatherMetrics.call(@campaign) }

      context "when promotion has daily_max_impressions" do
        context "when actual impressions are higher than daily max multiplier" do
          it "returns programatic promotion metrics" do
            promotion_metrics = {
              id: @promotion.id,
              impression_count: @difference * @max,
              click_count: @clicks
            }
            expect(subject).to eq [promotion_metrics]
          end
        end

        context "when actual impressions are lower than daily max multiplier" do
          before do
            @low_count = 5
            @promotion.promotable.update_attribute(:impression_count, @low_count)
          end

          it "returns actual metrics" do
            promotion_metrics = {
              id: @promotion.id,
              impression_count: @low_count,
              click_count: @clicks
            }
            expect(subject).to eq [promotion_metrics]
          end
        end
      end

      context "when daily max impressions not present" do
        before do
          @promotion.promotable.update_attributes(
            daily_max_impressions: nil,
            campaign_start: 4.days.ago,
            campaign_end: 1.day.ago
          )
          total_impressions = 5_000
          @campaign.update_attributes(
            ad_campaign_start: 20.days.ago,
            ad_campaign_end: 2.days.ago
          )
          campaign_length = (@campaign.ad_campaign_end - @campaign.ad_campaign_start).to_i + 1
          promotion_length = (@promotion.promotable.campaign_end - @promotion.promotable.campaign_start).to_i + 1
          @expected_view_count = (@total_impressions.to_f / campaign_length.to_f).to_i * promotion_length
        end

        it "returns programatic metrics" do
          promotion_metrics = {
            id: @promotion.id,
            impression_count: @expected_view_count,
            click_count: @clicks
          }
          expect(subject).to eq [promotion_metrics]
        end
      end
    end
  end
end