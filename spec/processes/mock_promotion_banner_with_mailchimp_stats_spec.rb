require 'spec_helper'

RSpec.describe MockPromotionBannerWithMailchimpStats do

  describe "::new" do
    before do
      @promotion_banner  = FactoryGirl.create :promotion_banner,
        promotion_type: PromotionBanner::DIGEST,
        campaign_start: Date.yesterday
      mailchimp_results = {
        :send_time      => "2017-03-01T10:55:28+00:00",
        :subscribers    => 471,
        :opens_total    => 163,
        :open_rate      => 0.34607218683652,
        :total_clicks   => 4
      }
      @mock = MockPromotionBannerWithMailchimpStats.new(
        promotion_banner: @promotion_banner,
        stats:            mailchimp_results
      )
    end

    it "responds to Mailchimp statistic-specific methods" do
      [:impression_count, :click_count].each do |method|
        expect(@mock.respond_to?(method)).to be true
      end
    end

    it "passes promotion_banner methods on to promotion_banner" do
      expect(@mock.campaign_start).to eq @promotion_banner.campaign_start
    end
  end
end