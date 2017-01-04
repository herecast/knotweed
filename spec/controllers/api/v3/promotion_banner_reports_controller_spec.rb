require 'spec_helper'

describe Api::V3::PromotionBannerReportsController, type: :controller do
  before do
    @org = FactoryGirl.create :organization
    @pb = FactoryGirl.create :promotion_banner, impression_count: 5,
      campaign_start: 5.days.ago, campaign_end: 5.days.from_now, promotion_type: 'ROS',
      cost_per_impression: 0.12
    @pbr = FactoryGirl.create :promotion_banner_report, report_date: Date.yesterday,
      promotion_banner: @pb
    @pb.promotion.update(paid: true, organization: @org)
    @other_pbr = FactoryGirl.create :promotion_banner_report, report_date: Date.current - 2.days, promotion_banner: @pb,
      impression_count: 3
  end

  subject { get :index, start_date: 3.day.ago.strftime("%D"), end_date: Date.today.strftime("%D") }

  it "returns appropriate information" do
    subject
    promotion_banner_report = JSON.parse(response.body)['promotion_banner_reports'][0]

    expect(promotion_banner_report).to match({
      "type" => @pb.promotion_type,
      "promo_id" => @pb.promotion.id,
      "banner_id" => @pb.id,
      "campaign_start" => @pb.campaign_start.strftime("%D"),
      "campaign_end" => @pb.campaign_end.strftime("%D"),
      "served" => @pb.impression_count,
      "cost" => @pb.cost_per_impression,
      "daily_max" => @pb.daily_max_impressions,
      "clicks" => @pb.click_count,
      "ctr" => "%.2f" % (@pb.click_count * 100.0 / @pb.impression_count),
      "client" => @org.name,
      "banner" => @pb.promotion.content.title,
      "daily_reports" => {
        Date.today.strftime("%D") => 0,
        1.day.ago.strftime("%D") => @pbr.impression_count,
        2.days.ago.strftime("%D") => @other_pbr.impression_count,
        3.days.ago.strftime("%D") => 0
      }
    })
  end
end
