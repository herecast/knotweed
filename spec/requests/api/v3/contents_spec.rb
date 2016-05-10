require 'spec_helper'

describe 'Contents Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/contents/:id/metrics' do
    let(:content) { FactoryGirl.create :content, created_by: user }

    it 'returns daily view counts' do
      (2.days.ago.to_date..Date.today).each do |date|
        FactoryGirl.create(:content_report, content: content, report_date: date)
      end

      get "/api/v3/contents/#{content.id}/metrics", {}, auth_headers
      expect(response.status).to eql 200

      expect(response_json['content_metrics']['daily_view_counts']).to_not be_empty
    end

    context 'Given 40 days of metrics data exist;' do
      before do
        (40.days.ago.to_date..Date.today).each do |date|
          FactoryGirl.create(:content_report, content: content, report_date: date)
        end
      end

      it 'returns all daily_view_counts by default' do
        get "/api/v3/contents/#{content.id}/metrics", {}, auth_headers
        view_counts = response_json['content_metrics']['daily_view_counts']
        expect(view_counts.count).to eql content.content_reports.count
      end

      it 'returns all daily_promo_click_thru_counts by default' do
        get "/api/v3/contents/#{content.id}/metrics", {}, auth_headers
        view_counts = response_json['content_metrics']['daily_promo_click_thru_counts']
        expect(view_counts.count).to eql content.content_reports.count
      end

      it 'orders daily_view_counts ASC on report_date' do
        get "/api/v3/contents/#{content.id}/metrics", {}, auth_headers

        view_counts = response_json['content_metrics']['daily_view_counts']
        report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context 'given a start_date parameter' do
        let(:start_date) { 25.days.ago.to_date }

        it 'returns daily_view_counts on or after the start_date' do
          get "/api/v3/contents/#{content.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json['content_metrics']['daily_view_counts']
          report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        it 'returns daily_promo_click_thru_counts on or after the start_date' do
          get "/api/v3/contents/#{content.id}/metrics", {
            start_date: start_date.to_date.to_s
          }, auth_headers
          view_counts = response_json['content_metrics']['daily_promo_click_thru_counts']
          report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
          expect(report_dates).to satisfy{|dates| dates.all?{|d| d >= start_date}}
        end

        context 'given a end_date parameter' do
          let(:end_date) { 2.days.ago.to_date }

          it 'returns daily_view_counts between start_date and end_date' do
            get "/api/v3/contents/#{content.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json['content_metrics']['daily_view_counts']
            report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end

          it 'returns daily_promo_click_thru_counts between start_date and end_date' do
            get "/api/v3/contents/#{content.id}/metrics", {
              start_date: start_date.to_date.to_s,
              end_date: end_date.to_date.to_s
            }, auth_headers
            view_counts = response_json['content_metrics']['daily_promo_click_thru_counts']
            report_dates = view_counts.map{|v| DateTime.parse(v['report_date']).to_date}
            expect(report_dates).to satisfy{|dates| dates.all?{|d| d.between?(start_date, end_date)}}
          end
        end
      end
    end
  end

  describe 'GET /api/v3/contents', type: :request do
    let(:org) { FactoryGirl.create :organization }
    let(:consumer_app) { FactoryGirl.create :consumer_app, organizations: [org] }
    let!(:default_location) { FactoryGirl.create :location, city: Location::DEFAULT_LOCATION }
    let!(:news_cat) { FactoryGirl.create :content_category, name: 'news'}
    let!(:event_cat) { FactoryGirl.create :content_category, name: 'event'}
    let!(:market_cat) { FactoryGirl.create :content_category, name: 'market'}
    let!(:talk_cat) { FactoryGirl.create :content_category, name: 'talk_of_the_town'}
    let!(:market_post_ugc) { FactoryGirl.create :content, organization: org,  channel_type: 'MarketPost', content_category: market_cat, locations: [default_location], published: true }
    let!(:market_post_listserv) { FactoryGirl.create :content, channel_type: nil, organization: org, content_category: market_cat, locations: [default_location], published: true }
    let(:headers) { {'ACCEPT' => 'application/json',
                     'Consumer-App-Uri' => consumer_app.uri
                  } }
    before { index }

    it 'should return only ugc market posts' do
      get "/api/v3/contents", {}, headers
      expect(response_json['contents'].map { |c| c['id'] } ).to match_array [market_post_ugc.id]
    end

    context 'with other content types' do
      let!(:news_post) { FactoryGirl.create :content, content_category: news_cat, organization: org, locations: [default_location], published: true }
      let!(:event) { FactoryGirl.create :content, content_category: event_cat, organization: org, locations: [default_location], published: true }
      let!(:event_instance) { FactoryGirl.create :event_instance, event: FactoryGirl.create(:event, content: event)}
      before { index }

      it 'they should be returned by the api' do
        get "/api/v3/contents", {}, headers
        expect(response_json['contents'].map { |c| c['id'] } ).to include event.id
        expect(response_json['contents'].map { |c| c['id'] } ).to include news_post.id
      end
    end

    context 'with deleted content' do
      let!(:news_post) { FactoryGirl.create :content, content_category: news_cat, organization: org, locations: [default_location], published: true, deleted_at: Time.now }
      before { index }

      it 'is not returned' do
        get "/api/v3/contents", {}, headers
        expect(response_json['contents'].map { |c| c['title'] } ).to_not include news_post.title
      end
    end
  end

  describe 'GET /api/v3/dashboard' do
    let(:news_cat) { ContentCategory.find_or_create_by name: 'news' }
    context 'user has deleted content' do
      let!(:deleted_news) { FactoryGirl.create :content,
                           content_category: news_cat,
                           created_by: user,
                           published: true,
                           deleted_at: Time.now}

      it 'does not return deleted content' do
        get '/api/v3/dashboard', {}, auth_headers
        ids = response_json['contents'].map{|i| i['id']}

        expect(ids).to_not include(deleted_news.id)
      end
    end
  end

end
