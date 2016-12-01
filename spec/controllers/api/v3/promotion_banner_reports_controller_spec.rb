require 'spec_helper'

describe Api::V3::PromotionBannerReportsController, type: :controller do
  before do
    @promotion_banner_report = FactoryGirl.create :promotion_banner_report, report_date: Date.yesterday
    @promotion_banner_report.promotion_banner.promotion.update_attribute(:paid, 't')
  end

  subject { get :index }

  it "returns appropriate information" do
    subject
    promotion_banner_report = JSON.parse(response.body)['promotion_banner_reports'][0]

    expect(promotion_banner_report).to match({
      "promotion_id" => @promotion_banner_report.promotion_banner.promotion.id.to_s,
      "title" => @promotion_banner_report.promotion_banner.promotion.content.title,
      "paid" => 't',
      "report_date" => @promotion_banner_report.report_date.strftime("%Y-%m-%d %T"),
      "daily_impression_count" => @promotion_banner_report.impression_count.to_s,
      "daily_click_count" => @promotion_banner_report.click_count.to_s,
      "total_impression_count" => @promotion_banner_report.total_impression_count,
      "total_click_count" => @promotion_banner_report.total_click_count,
      "campaign_start" => @promotion_banner_report.promotion_banner.campaign_start.strftime("%Y-%m-%d"),
      "campaign_end" => @promotion_banner_report.promotion_banner.campaign_end.strftime("%Y-%m-%d"),
      "max_impressions" => @promotion_banner_report.promotion_banner.max_impressions.to_s,
      "content_id" => @promotion_banner_report.promotion_banner.promotion.content.id.to_s,
      "promotion_banner_id" => @promotion_banner_report.promotion_banner_id.to_s
    })
  end
end
