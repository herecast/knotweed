require 'spec_helper'



describe 'Contents Endpoints', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/contents/:id' do
    let(:org) { FactoryGirl.create :organization }
    let(:consumer_app) { FactoryGirl.create :consumer_app, organizations: [org] }
    let(:headers) { {'ACCEPT' => 'application/json',
                     'Consumer-App-Uri' => consumer_app.uri
                  } }
    let(:content) { FactoryGirl.create :content, organization: org }

    context "when no requesting app" do
      subject { get "/api/v3/contents/#{content.id}" }

      it 'does not return content' do
        subject
        expect(response_json).to eq({})
      end
    end

    context "when appropriate requesting app" do
      subject { get "/api/v3/contents/#{content.id}", {}, headers }

      it "returns content record" do
        subject
        expect(response_json[:content]).not_to be nil
      end
    end

    describe 'when content requested is of listserv origin' do
      let(:listserv_org) {
        FactoryGirl.create(:organization,
          id: Organization::LISTSERV_ORG_ID
        )
      }
      before do
        consumer_app.update organizations: [listserv_org]
        content.update organization: listserv_org
      end

      subject { get "/api/v3/contents/#{content.id}", {}, headers }

      context 'user is not signed in' do
        it 'returns a 401 status' do
          subject
          expect(response.code).to eql "401"
        end
      end

      context 'user is signed in' do
        let(:user) { FactoryGirl.create :user }
        let(:auth_headers) { auth_headers_for(user) }
        before do
          headers.merge! auth_headers
        end

        it 'returns a 200 status' do
          subject
          expect(response.code).to eql "200"
        end
      end
    end
  end

  describe 'GET /api/v3/contents/:id/metrics' do
    before do
      @content = FactoryGirl.create :content, created_by: user
    end

    context "when no start_date or end_date" do
      subject { get "/api/v3/contents/#{@content.id}/metrics", {}, auth_headers }

      it "returns bad_request status" do
        subject
        expect(response.status).to eql 400
      end
    end

    context "when start_date and end_date present" do
      before do
        date_range = (2.days.ago.to_date..Date.current)
        @start_date = date_range.first.to_s
        @end_date = date_range.last.to_s
        date_range.each do |date|
          FactoryGirl.create(:content_report, content: @content, report_date: date)
        end
      end

      let(:expected_response) {{
        id: @content.id,
        title: @content.title,
        image_url: @content.primary_image&.image_url,
        view_count: 0,
        comment_count: 0,
        comments: [],
        promo_click_thru_count: @content.banner_click_count,
        daily_view_counts: @content.content_reports.map{ |cr|
          cr.view_count_hash
        },
        daily_promo_click_thru_counts: @content.content_reports.map{ |cr|
          cr.banner_click_hash
        }
      }}

      subject { get "/api/v3/contents/#{@content.id}/metrics?start_date=#{@start_date}&end_date=#{@end_date}", {}, auth_headers }

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

      subject { get "/api/v3/contents/#{@content.id}/metrics?start_date=#{@start_date}&end_date=#{@end_date}", {}, auth_headers }

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
        report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context "when days are missing reports" do
        before do
          ContentReport.all[10..12].each { |cr| cr.delete }
          @expected_nuber_of_reports = 41
        end

        it "returns expected number of daily reports" do
          subject
          view_counts = response_json[:content_metrics][:daily_view_counts]
          expect(view_counts.count).to eql @expected_nuber_of_reports
          click_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
          expect(click_counts.count).to eql @expected_nuber_of_reports
        end
      end
    end
  end

  describe 'GET /api/v3/contents/sitemap_ids' do
    let!(:org) { FactoryGirl.create :organization }
    let!(:alt_org) { FactoryGirl.create :organization }
    let!(:location) { FactoryGirl.create(:location)}

    let!(:consumer_app) { FactoryGirl.create :consumer_app_dailyuv, organizations: [org] }

    let!(:event) {
      FactoryGirl.create :content, :event, :published, organization: org
    }
    let!(:talk) {
      FactoryGirl.create :content, :talk, :published, organization: org
    }
    let!(:market_post) {
      FactoryGirl.create :content, :market_post, :published, organization: org
    }
    let!(:news) {
      FactoryGirl.create :content, :news, :published, organization: org
    }
    let!(:comment) {
      FactoryGirl.create :comment
    }

    before do
      comment.content.update organization: org
    end

    let(:query_params) { {} }

    subject do
      get '/api/v3/contents/sitemap_ids', query_params
      response_json
    end

    it 'returns the ids of the contents as expected (not events or comments by default)' do
      expect(subject[:content_ids]).to include *[talk, market_post, news].map(&:id)
      expect(subject[:content_ids]).to_not include event.id
      expect(subject[:content_ids]).to_not include comment.content.id
    end

    it 'does not return content that does not have at least one content_location that is not base' do
      news.update locations: []
      news.update base_locations: [location]
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include listserv content' do
      market_post.update organization_id: Organization::LISTSERV_ORG_ID
      expect(subject[:content_ids]).to_not include market_post.id
    end

    it 'allows specifying type separated by comma' do
      query_params[:type] = 'news,market'
      expect(subject[:content_ids]).to include *[news.id, market_post.id]
      expect(subject[:content_ids]).to_not include talk.id
    end

    it 'does not include content if not published' do
      news.update published: false
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content if pubdate is null' do
      news.update pubdate: nil
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content if pubdate is in the future' do
      news.update pubdate: Time.zone.now.tomorrow
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content removed' do
      news.update removed: true
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include non-dailyuv content' do
      event.update organization_id: alt_org.id
      expect(subject[:content_ids]).to_not include event.id
    end
  end
end
