require 'spec_helper'

describe Api::V3::PromotionBannerReportsController, type: :controller do
  around(:each) do |example|
    Timecop.freeze Time.zone.now.beginning_of_day - 6.hours do
      example.run
    end
  end

  describe "GET #index" do
    before do
      @org = FactoryGirl.create :organization
      @pb = FactoryGirl.create :promotion_banner, impression_count: 5,
        campaign_start: 5.days.ago, campaign_end: 5.days.from_now, promotion_type: 'ROS',
        cost_per_impression: 0.12, sales_agent: 'LSW'
      @pbr = FactoryGirl.create :promotion_banner_report, report_date: Date.yesterday,
        promotion_banner: @pb
      @pb.promotion.update(paid: true, organization: @org)
      @other_pbr = FactoryGirl.create :promotion_banner_report, report_date: Date.current - 2.days, promotion_banner: @pb,
        impression_count: 3
    end

    subject { get :index, params: { start_date: 3.day.ago.strftime("%D"), end_date: Date.today.strftime("%D") } }

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
        "daily_cost" => @pb.cost_per_day,
        "daily_max" => @pb.daily_max_impressions,
        "clicks" => @pb.click_count,
        "ctr" => "%.2f" % (@pb.click_count * 100.0 / @pb.impression_count),
        "client" => @org.name,
        "banner" => @pb.promotion.content.title,
        "paid" => @pb.promotion.paid,
        "sales_agent" => @pb.sales_agent,
        "daily_reports" => {
          Date.today.strftime("%D") => 0,
          1.day.ago.strftime("%D") => @pbr.impression_count,
          2.days.ago.strftime("%D") => @other_pbr.impression_count,
          3.days.ago.strftime("%D") => 0
        }
      })
    end
  end

  describe 'GET #show_daily_reports' do
    before do
      @promotion_banner_report_one = FactoryGirl.create :promotion_banner_report,
        report_date: Date.yesterday
      @promotion_banner_report_two = FactoryGirl.create :promotion_banner_report,
        impression_count: 5,
        report_date: Date.yesterday
      @promotion_banner_report_one.promotion_banner.update_attribute :cost_per_day, 6.43
      @promotion_banner_report_two.promotion_banner.update_attribute :cost_per_impression, 0.15
      PromotionBanner.all.each { |pb| pb.promotion.update_attribute(:paid, true) }
    end

    subject { get :show_daily_report, params: { report_date: Date.yesterday } }

    it "returns revenue information for specific date" do
      subject
      report = JSON.parse(response.body)["report"]
      expect(report).to match_array([
        {
          "promotion_id" => @promotion_banner_report_one.promotion_banner.promotion.id,
          "title" => @promotion_banner_report_one.promotion_banner.promotion.content.title,
          "type" => "Cost type: Per day, 6.43",
          "impression_count" => @promotion_banner_report_one.impression_count,
          "revenue" => @promotion_banner_report_one.promotion_banner.cost_per_day
        }, {
          "promotion_id" => @promotion_banner_report_two.promotion_banner.promotion.id,
          "title" => @promotion_banner_report_two.promotion_banner.promotion.content.title,
          "type" => "Cost type: Per impression, 0.15",
          "impression_count" => @promotion_banner_report_two.impression_count,
          "revenue" => @promotion_banner_report_two.impression_count * @promotion_banner_report_two.promotion_banner.cost_per_impression
        }
      ])
    end
  end

  describe 'GET #show_monthly_projections' do
    before do
      @active_daily_cost_pb_report = FactoryGirl.create :promotion_banner_report,
        report_date: Date.current
      @active_impression_cost_pb_report = FactoryGirl.create :promotion_banner_report,
        report_date: Date.current,
        impression_count: 5
      @inactive_ad_report = FactoryGirl.create :promotion_banner_report,
        report_date: Date.current
      @active_daily_cost_pb_report.promotion_banner.update_attributes(
        cost_per_day: 6.43,
        campaign_start: Date.current,
        campaign_end:   Date.current
      )
      @active_impression_cost_pb_report.promotion_banner.update_attributes(
        cost_per_impression: 0.15,
        campaign_start:      Date.current,
        campaign_end:        Date.current
      )
      @inactive_ad_report.promotion_banner.update_attributes(
        cost_per_day:   7.58,
        campaign_start: 60.days.from_now,
        campaign_end:   60.days.from_now
      )
      PromotionBanner.all.each { |pb| pb.promotion.update_attribute(:paid, true) }
    end

    subject { get :show_monthly_projection}

    it "returns projected total" do
      subject
      total_from_first = (@active_daily_cost_pb_report.promotion_banner.cost_per_day * 1)
      total_from_second = (@active_impression_cost_pb_report.impression_count * @active_impression_cost_pb_report.promotion_banner.cost_per_impression)
      expected_total = total_from_first + total_from_second
      expect(JSON.parse(response.body)['current_month_revenue_projection'].to_f).to eq expected_total
    end
  end
end
