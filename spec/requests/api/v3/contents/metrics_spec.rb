require 'spec_helper'

RSpec.describe 'Content Metrics Endpoints', type: :request do
  describe 'GET /api/v3/contents/:id/metrics' do
    before do
      @content = FactoryGirl.create :content, created_by: user
    end

    let(:user) { FactoryGirl.create :user }
    let(:auth_headers) { auth_headers_for(user) }

    context 'when no start_date or end_date' do
      subject { get "/api/v3/contents/#{@content.id}/metrics", params: {}, headers: auth_headers }

      it 'returns bad_request status' do
        subject
        expect(response.status).to eql 400
      end
    end

    context 'when start_date and end_date present' do
      before do
        date_range = (2.days.ago.to_date..Date.current)
        @start_date = date_range.first.to_s
        @end_date = date_range.last.to_s
        date_range.each do |date|
          FactoryGirl.create(:content_report, content: @content, report_date: date)
        end
      end

      let(:expected_response) do
        {
          id: @content.id,
          title: @content.title,
          image_url: @content.primary_image&.image_url,
          view_count: 0,
          comment_count: 0,
          comments: [],
          promo_click_thru_count: @content.banner_click_count,
          daily_view_counts: @content.content_reports.map(&:view_count_hash),
          daily_promo_click_thru_counts: @content.content_reports.map(&:banner_click_hash)
        }
      end

      subject { get "/api/v3/contents/#{@content.id}/metrics?start_date=#{@start_date}&end_date=#{@end_date}", params: {}, headers: auth_headers }

      it 'returns daily view counts' do
        subject
        expect(response_json[:content_metrics]).to include expected_response
      end
    end

    context 'Given 40 days of metrics data exist;' do
      before do
        date_range = (40.days.ago.to_date..Date.current)
        @start_date = date_range.first.to_s
        @end_date = date_range.last.to_s
        date_range.each do |date|
          FactoryGirl.create(:content_report, content: @content, report_date: date)
        end
      end

      subject { get "/api/v3/contents/#{@content.id}/metrics?start_date=#{@start_date}&end_date=#{@end_date}", params: {}, headers: auth_headers }

      it 'returns all daily_view_counts by default' do
        subject
        view_counts = response_json[:content_metrics][:daily_view_counts]
        expect(view_counts.count).to eql @content.content_reports.count
      end

      it 'returns all daily_promo_click_thru_counts by default' do
        subject
        view_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
        expect(view_counts.count).to eql @content.content_reports.count
      end

      it 'orders daily_view_counts ASC on report_date' do
        subject
        view_counts = response_json[:content_metrics][:daily_view_counts]
        report_dates = view_counts.map { |v| DateTime.parse(v[:report_date]).to_date }
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context 'when days are missing reports' do
        before do
          ContentReport.all[10..12].each(&:delete)
          @expected_nuber_of_reports = 41
        end

        it 'returns expected number of daily reports' do
          subject
          view_counts = response_json[:content_metrics][:daily_view_counts]
          expect(view_counts.count).to eql @expected_nuber_of_reports
          click_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
          expect(click_counts.count).to eql @expected_nuber_of_reports
        end
      end
    end
  end
end