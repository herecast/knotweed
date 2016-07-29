require 'spec_helper'

describe 'Promotion Banner Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/promotion_banners/:id/metrics' do
    let(:promotion) { FactoryGirl.create :promotion, created_by: user }
    let(:promotion_banner) { FactoryGirl.create :promotion_banner, promotion: promotion }

    it 'returns daily impression and click counts' do
      (2.days.ago.to_date..Date.current).each do |date|
        FactoryGirl.create(:promotion_banner_report, promotion_banner: promotion_banner, report_date: date)
      end

      get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers
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
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers
        impression_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
        expect(impression_counts.count).to eql promotion_banner.promotion_banner_reports.count
      end

      it 'returns all daily_click_counts by default' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers
        click_counts = response_json[:promotion_banner_metrics][:daily_click_counts]
        expect(click_counts.count).to eql promotion_banner.promotion_banner_reports.count
      end

      it 'orders daily_impression_counts ASC on report_date' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers

        view_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
        report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context 'with empty string dates' do
          subject { get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
            start_date: " ", end_date: " "
          }, auth_headers }

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
          get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
          report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        it 'returns daily_click_counts on or after the start_date' do
          get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json[:promotion_banner_metrics][:daily_click_counts]
          report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        context 'given a end_date parameter' do
          let(:end_date) { 2.days.ago.to_date }

          it 'returns daily_view_counts between start_date and end_date' do
            get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json[:promotion_banner_metrics][:daily_impression_counts]
            report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end

          it 'returns daily_click_counts between start_date and end_date' do
            get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json[:promotion_banner_metrics][:daily_click_counts]
            report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end
        end
      end
    end
  end

  describe 'GET /api/v3/promotion' do
    let(:organization) { FactoryGirl.create :organization }
    let!(:banner) { FactoryGirl.create :promotion_banner }

    context 'with existing content and related promotion;' do
      let!(:promo) { FactoryGirl.create :promotion, organization: organization, promotable: banner }
      let!(:content) { FactoryGirl.create :content, banner_ad_override: promo.id }

      subject { get "/api/v3/promotion?content_id=#{content.id}" }

      it 'returns promotion json' do
        subject
        expect(response_json).to match(
          promotion: {
            image_url: banner.banner_image.url,
            redirect_url: banner.redirect_url,
            banner_id: banner.id,
            organization_name: organization.name,
            promotion_id: promo.id
          }
        )
      end
    end

    context 'with existing organization and related promotion' do
      let!(:promo) { FactoryGirl.create :promotion, promotable_id: banner.id, promotable_type: 'PromotionBanner' }
      let!(:new_organization) { FactoryGirl.create :organization, banner_ad_override: promo.id }

      subject { get "/api/v3/promotion?organization_id=#{new_organization.id}" }

      it 'returns promotion json' do
        allow(PromotionBanner).to receive(:get_random_promotion).and_return nil
        subject
        expect(response_json).to match(
          promotion: {
            image_url: banner.banner_image.url,
            redirect_url: banner.redirect_url,
            banner_id: banner.id,
            organization_name: nil,
            promotion_id: promo.id
          }
        )
      end
    end
  end
end
