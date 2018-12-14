# frozen_string_literal: true

require 'spec_helper'

def public_promotion_banner_schema(promotion_banner)
  {
    id: promotion_banner.id,
    title: promotion_banner.promotion.content.title,
    pubdate: promotion_banner.promotion.content.pubdate.try(:iso8601),
    image_url: promotion_banner.banner_image.url,
    redirect_url: promotion_banner.redirect_url,
    campaign_start: promotion_banner.campaign_start.try(:iso8601),
    campaign_end: promotion_banner.campaign_end.try(:iso8601),
    max_impressions: promotion_banner.max_impressions,
    impression_count: promotion_banner.impression_count,
    click_count: promotion_banner.click_count,
    content_type: 'promotion_banner',
    description: promotion_banner.promotion.description,
    digest_emails: promotion_banner.digest_emails
  }
end

describe 'Promotion Banner Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/promotion_banners/:id/metrics' do
    before do
      @promotion = FactoryGirl.create :promotion, created_by: user
    end
    let(:promotion_banner) { FactoryGirl.create :promotion_banner, promotion: @promotion }

    it 'returns daily impression and click counts' do
      (2.days.ago.to_date..Date.current).each do |date|
        FactoryGirl.create(:promotion_banner_report, promotion_banner: promotion_banner, report_date: date)
      end

      get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {}, headers: auth_headers
      expect(response.status).to eql 200

      expect(response_json[:promotion_banner_metrics][:daily_impression_counts]).to_not be_empty
      expect(response_json[:promotion_banner_metrics][:daily_impression_counts][0][:report_date]).to_not be_nil
      expect(response_json[:promotion_banner_metrics][:daily_impression_counts][0][:impression_count]).to_not be_nil

      expect(response_json[:promotion_banner_metrics][:daily_click_counts]).to_not be_empty
      expect(response_json[:promotion_banner_metrics][:daily_click_counts][0][:report_date]).to_not be_nil
      expect(response_json[:promotion_banner_metrics][:daily_click_counts][0][:click_count]).to_not be_nil
    end

    context 'Given 40 days of metrics data exist;' do
      before do
        (40.days.ago.to_date..Date.current).each do |date|
          FactoryGirl.create(:promotion_banner_report, promotion_banner: promotion_banner, report_date: date)
        end
      end

      it 'returns all daily_impression_counts by default' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {}, headers: auth_headers
        impression_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
        expect(impression_counts.count).to eql promotion_banner.promotion_banner_reports.count
      end

      it 'returns all daily_click_counts by default' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {}, headers: auth_headers
        click_counts = response_json[:promotion_banner_metrics][:daily_click_counts]
        expect(click_counts.count).to eql promotion_banner.promotion_banner_reports.count
      end

      it 'orders daily_impression_counts ASC on report_date' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {}, headers: auth_headers

        view_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
        report_dates = view_counts.map { |v| DateTime.parse(v[:report_date]).to_date }
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context 'with empty string dates' do
        subject do
          get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {
            start_date: ' ', end_date: ' '
          }, headers: auth_headers
        end

        it 'should return all daily_impression_counts' do
          subject
          expect(response_json[:promotion_banner_metrics][:daily_impression_counts].count).to eql promotion_banner.promotion_banner_reports.count
        end

        it 'should return all daily_click_counts' do
          subject
          expect(response_json[:promotion_banner_metrics][:daily_click_counts].count).to eql promotion_banner.promotion_banner_reports.count
        end
      end

      context 'given a start_date parameter' do
        let(:start_date) { 25.days.ago.to_date }

        it 'returns daily_impression_counts on or after the start_date' do
          get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {
            start_date: start_date.to_date.to_s
          }, headers: auth_headers
          view_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
          report_dates = view_counts.map { |v| DateTime.parse(v[:report_date]).to_date }
          expect(report_dates).to satisfy { |dates| dates.all? { |d| d >= start_date } }
        end

        it 'returns daily_click_counts on or after the start_date' do
          get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {
            start_date: start_date.to_date.to_s
          }, headers: auth_headers
          view_counts = response_json[:promotion_banner_metrics][:daily_click_counts]
          report_dates = view_counts.map { |v| DateTime.parse(v[:report_date]).to_date }
          expect(report_dates).to satisfy { |dates| dates.all? { |d| d >= start_date } }
        end

        context 'given a end_date parameter' do
          let(:end_date) { 2.days.ago.to_date }

          it 'returns daily_view_counts between start_date and end_date' do
            get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, headers: auth_headers
            view_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
            report_dates = view_counts.map { |v| DateTime.parse(v[:report_date]).to_date }
            expect(report_dates).to satisfy { |dates| dates.all? { |d| d.between?(start_date, end_date) } }
          end

          it 'returns daily_click_counts between start_date and end_date' do
            get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", params: {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, headers: auth_headers
            view_counts = response_json[:promotion_banner_metrics][:daily_click_counts]
            report_dates = view_counts.map { |v| DateTime.parse(v[:report_date]).to_date }
            expect(report_dates).to satisfy { |dates| dates.all? { |d| d.between?(start_date, end_date) } }
          end
        end
      end
    end
  end

  describe 'GET /api/v3/promotions' do
    let(:organization) { FactoryGirl.create :organization }

    context 'with existing content and related promotion;' do
      let(:banner) { FactoryGirl.create :promotion_banner }
      let(:promo) { banner.promotion }
      let!(:content) { FactoryGirl.create :content, banner_ad_override: promo.id, organization: organization }

      subject { get "/api/v3/promotions?content_id=#{content.id}" }

      it 'returns promotion json' do
        subject
        expect(response_json[:promotions].first).to match(
          id: banner.id,
          image_url: banner.banner_image.url,
          redirect_url: banner.redirect_url,
          organization_name: an_instance_of(String),
          promotion_id: promo.id,
          title: promo.content.title,
          select_score: be_an_instance_of(Float).or(be_nil),
          select_method: 'sponsored_content'
        )
      end
    end

    context 'with existing organization and related promotion' do
      let(:banner) { FactoryGirl.create :promotion_banner }
      let(:promo) { banner.promotion }
      let!(:new_organization) { FactoryGirl.create :organization, banner_ad_override: promo.id }

      subject { get "/api/v3/promotions?organization_id=#{new_organization.id}" }

      it 'returns promotion json' do
        allow(PromotionBanner).to receive(:get_random_promotion).and_return nil
        subject
        expect(response_json).to match(
          promotions: [{
            id: banner.id,
            image_url: banner.banner_image.url,
            redirect_url: banner.redirect_url,
            organization_name: promo.content.organization.name,
            promotion_id: promo.id,
            title: promo.content.title,
            select_score: be_an_instance_of(Float).or(be_nil),
            select_method: 'sponsored_content'
          }]
        )
      end
    end
  end

  describe 'GET /api/v3/promotions/:promotion_id' do
    let!(:other_banner) { FactoryGirl.create :promotion_banner }
    let!(:banner) { FactoryGirl.create :promotion_banner, id: 200 }

    subject { get "/api/v3/promotions/#{banner.promotion.id}" }

    it 'returns promotion json' do
      subject
      expect(response_json).to match(
        promotions: [{
          id: banner.id,
          image_url: banner.banner_image.url,
          redirect_url: banner.redirect_url,
          organization_name: an_instance_of(String) | be_nil,
          promotion_id: banner.promotion.id,
          title: banner.promotion.content.title,
          select_score: be_an_instance_of(Float).or(be_nil),
          select_method: 'sponsored_content'
        }]
      )
    end

    context 'when promotion_banner is type: coupon' do
      before do
        @promotion_coupon = FactoryGirl.create :promotion_banner,
                                               promotion_type: 'Coupon',
                                               coupon_image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
      end

      subject { get "/api/v3/promotions/#{@promotion_coupon.promotion.id}" }

      it 'returns automated redirect_url' do
        subject
        expect(response_json[:promotions][0][:redirect_url]).to eq "/promotions/#{@promotion_coupon.id}"
      end
    end
  end
end
