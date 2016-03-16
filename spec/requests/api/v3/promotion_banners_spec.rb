require 'spec_helper'

describe 'Promotion Banner Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/promotion_banners/:id/metrics' do
    let(:promotion) { FactoryGirl.create :promotion, created_by: user }
    let(:promotion_banner) { FactoryGirl.create :promotion_banner, promotion: promotion }

    it 'returns daily impression and click counts' do
      (2.days.ago.to_date..Date.today).each do |date|
        FactoryGirl.create(:promotion_banner_report, promotion_banner: promotion_banner, report_date: date)
      end

      get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers
      expect(response.status).to eql 200

      expect(response_json['promotion_banner_metrics']['daily_impression_counts']).to_not be_empty
      expect(response_json['promotion_banner_metrics']['daily_impression_counts'][0]['report_date']).to_not be_nil
      expect(response_json['promotion_banner_metrics']['daily_impression_counts'][0]['impression_count']).to_not be_nil

      expect(response_json['promotion_banner_metrics']['daily_click_counts']).to_not be_empty
      expect(response_json['promotion_banner_metrics']['daily_click_counts'][0]['report_date']).to_not be_nil
      expect(response_json['promotion_banner_metrics']['daily_click_counts'][0]['click_count']).to_not be_nil
    end

    context 'Given 40 days of metrics data exist;' do
      before do
        (40.days.ago.to_date..Date.today).each do |date|
          FactoryGirl.create(:promotion_banner_report, promotion_banner: promotion_banner, report_date: date)
        end
      end

      it 'returns all daily_impression_counts by default' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers
        impression_counts = response_json['promotion_banner_metrics']['daily_impression_counts']
        expect(impression_counts.count).to eql promotion_banner.promotion_banner_reports.count
      end

      it 'returns all daily_click_counts by default' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers
        click_counts = response_json['promotion_banner_metrics']['daily_click_counts']
        expect(click_counts.count).to eql promotion_banner.promotion_banner_reports.count
      end

      it 'orders daily_impression_counts ASC on report_date' do
        get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {}, auth_headers

        view_counts = response_json['promotion_banner_metrics']['daily_impression_counts']
        report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context 'given a start_date parameter' do
        let(:start_date) { 25.days.ago.to_date }

        it 'returns daily_impression_counts on or after the start_date' do
          get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json['promotion_banner_metrics']['daily_impression_counts']
          report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        it 'returns daily_click_counts on or after the start_date' do
          get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json['promotion_banner_metrics']['daily_click_counts']
          report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        context 'given a end_date parameter' do
          let(:end_date) { 2.days.ago.to_date }

          it 'returns daily_view_counts between start_date and end_date' do
            get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json['promotion_banner_metrics']['daily_impression_counts']
            report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end

          it 'returns daily_click_counts between start_date and end_date' do
            get "/api/v3/promotion_banners/#{promotion_banner.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json['promotion_banner_metrics']['daily_click_counts']
            report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end
        end
      end
    end
  end
end
