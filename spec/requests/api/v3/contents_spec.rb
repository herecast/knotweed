require 'spec_helper'

describe 'Contents Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/contents/:id/metrics' do
    before do
      @content = FactoryGirl.create :content, created_by: user
    end

    it 'returns daily view counts' do
      (2.days.ago.to_date..Date.current).each do |date|
        FactoryGirl.create(:content_report, content: @content, report_date: date)
      end

      get "/api/v3/contents/#{@content.id}/metrics", {}, auth_headers
      expect(response.status).to eql 200

      expect(response_json[:content_metrics][:daily_view_counts]).to_not be_empty
    end

    context 'Given 40 days of metrics data exist;' do
      before do
        (40.days.ago.to_date..Date.current).each do |date|
          FactoryGirl.create(:content_report, content: @content, report_date: date)
        end
      end

      it 'returns all daily_view_counts by default' do
        get "/api/v3/contents/#{@content.id}/metrics", {}, auth_headers
        view_counts = response_json[:content_metrics][:daily_view_counts]
        expect(view_counts.count).to eql @content.content_reports.count
      end

      it 'returns all daily_promo_click_thru_counts by default' do
        get "/api/v3/contents/#{@content.id}/metrics", {}, auth_headers
        view_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
        expect(view_counts.count).to eql @content.content_reports.count
      end

      it 'orders daily_view_counts ASC on report_date' do
        get "/api/v3/contents/#{@content.id}/metrics", {}, auth_headers

        view_counts = response_json[:content_metrics][:daily_view_counts]
        report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context 'given a start_date parameter' do
        let(:start_date) { 25.days.ago.to_date }

        it 'returns daily_view_counts on or after the start_date' do
          get "/api/v3/contents/#{@content.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json[:content_metrics][:daily_view_counts]
          report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        it 'returns daily_promo_click_thru_counts on or after the start_date' do
          get "/api/v3/contents/#{@content.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
          report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        context 'given a end_date parameter' do
          let(:end_date) { 2.days.ago.to_date }

          it 'returns daily_view_counts between start_date and end_date' do
            get "/api/v3/contents/#{@content.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json[:content_metrics][:daily_view_counts]
            report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end

          it 'returns daily_promo_click_thru_counts between start_date and end_date' do
            get "/api/v3/contents/#{@content.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
            report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end
        end
      end
    end
  end

  describe 'GET /api/v3/dashboard' do
    let(:news_cat) { ContentCategory.find_or_create_by name: 'news' }
    let(:market_cat) { ContentCategory.find_or_create_by name: 'market' }
    context 'user has deleted content' do
      let!(:deleted_news) { FactoryGirl.create :content,
                           content_category: news_cat,
                           created_by: user,
                           published: true,
                           deleted_at: Time.current}
      let!(:old_news_content) { FactoryGirl.create :content,
                                content_category: news_cat,
                                created_by: user,
                                pubdate: 2.days.ago,
                                published: true }
      let!(:recent_news_content) { FactoryGirl.create :content,
                                  content_category: news_cat,
                                  created_by: user,
                                  published: true }

      it 'does not return deleted content' do
        get '/api/v3/dashboard', {}, auth_headers
        ids = response_json[:contents].map{|i| i['id']}

        expect(ids).to_not include(deleted_news.id)
      end

      it 'falls back to sorting on pubdate when trying to sort on start_date' do
        get '/api/v3/dashboard', { page: 1, per_page: 8, sort: 'start_date ASC', channel_type: 'news' }, auth_headers
        expect(response_json[:contents].first[:id]).to eq old_news_content.id
      end
    end

    context 'user is selling items in the market' do
      let!(:post_content) { FactoryGirl.create :content, published: true, content_category: market_cat }
      let!(:market_post) { FactoryGirl.create :market_post, content: post_content, sold: true }

    before do
      market_post.created_by = user
      market_post.save!
    end
      
      it 'displays their current items in the market' do
        get '/api/v3/dashboard', { channel_type: 'market' }, auth_headers
        post = response_json[:contents].first
        expect(post[:title]).to eq(post_content.title)
        expect(post[:sold]).to eq true
      end
    end
  end
end
