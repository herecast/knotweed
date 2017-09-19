require 'spec_helper'

describe 'Contents Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/contents', elasticsearch: true do
    let(:org) { FactoryGirl.create :organization }
    let(:consumer_app) { FactoryGirl.create :consumer_app, organizations: [org] }
    let(:headers) { {'ACCEPT' => 'application/json',
                     'Consumer-App-Uri' => consumer_app.uri
                  } }

    let(:locations) {
      FactoryGirl.create_list(:location, 2)
    }
    let(:user) {
      FactoryGirl.create(:user)
    }
    let!(:news) {
      FactoryGirl.create :content, :news,
        created_by: user,
        organization: org,
        published: true,
        locations: locations,
        images: [FactoryGirl.build(:image, :primary)]
    }
    let!(:event) {
      FactoryGirl.create :content, :event,
        created_by: user,
        organization: org,
        locations: locations,
        published: true,
        images: [FactoryGirl.build(:image, :primary)]
    }
    let!(:market) {
      FactoryGirl.create :content, :market_post,
        created_by: user,
        organization: org,
        locations: locations,
        published: true,
        images: [FactoryGirl.build(:image, :primary)]
    }
    let!(:talk) {
      FactoryGirl.create :content, :talk,
        created_by: user,
        organization: org,
        locations: locations,
        published: true,
        images: [FactoryGirl.build(:image, :primary)]
    }
    let!(:comment) {
      FactoryGirl.create :content, :talk, organization: org, channel_type: 'Comment', published: true
    }

    it 'returns news content in expected format' do
      get "/api/v3/contents", {}, headers
      serialized_news = response_json[:contents].find{|i| i[:content_type] == 'news'}

      expect(serialized_news).to include({
        id: news.id,
        title: news.title,
        image_url: news.images[0].url,
        author_id: news.created_by.id,
        author_name: news.author_name,
        content_type: 'news',
        organization_id: org.id,
        organization_name: org.name,
        subtitle: news.subtitle,
        venue_zip: nil,
        published_at: news.pubdate.iso8601,
        starts_at: nil,
        ends_at: nil,
        content: news.sanitized_content,
        view_count: news.view_count,
        commenter_count: 0,
        comment_count: 0,
        parent_content_id: nil,
        content_id: news.id,
        parent_content_type: nil,
        event_instance_id: nil,
        parent_event_instance_id: nil,
        registration_deadline: nil,
        created_at: news.created_at.iso8601,
        updated_at: news.updated_at.iso8601,
        event_id: nil,
        cost: nil,
        sold: nil,
        avatar_url: news.created_by.avatar_url,
        organization_profile_image_url: nil,
        biz_feed_public: news.biz_feed_public?,
        sunset_date: news.sunset_date.try(:iso8601),
        images: news.images.map do |image|
            {
              id: image.id,
              image_url: image.image.url,
              primary: (image.primary? ? 1 : 0),
              width: image.width,
              height: image.height,
              file_extension: image.file_extension
            }
          end,
        can_edit: false,
        event_instances: nil,
        content_origin: 'ugc',
        split_content: a_hash_including({
          head: an_instance_of(String),
          tail: an_instance_of(String)
        }),
        cost_type: nil,
        contact_phone: nil,
        contact_email: nil,
        venue_url: nil,
        content_locations: news.content_locations.map do |cl|
          {
            id: cl.id,
            location_id: cl.location.slug,
            location_type: cl.location_type,
            location_name: cl.location.name
          }
        end
      })
    end

    it 'returns events content in expected format' do
      get "/api/v3/contents", {}, headers
      serialized_event = response_json[:contents].find{|i| i[:content_type] == 'event'}

      expect(serialized_event).to include({
        id: event.id,
        title: event.title,
        image_url: event.images[0].url,
        author_id: event.created_by.id,
        author_name: event.author_name,
        content_type: 'event',
        organization_id: org.id,
        organization_name: org.name,
        subtitle: event.subtitle,
        published_at: event.pubdate.iso8601,
        starts_at: event.channel.next_or_first_instance.start_date.try(:iso8601),
        ends_at: event.channel.next_or_first_instance.end_date.try(:iso8601),
        content: event.sanitized_content,
        view_count: event.view_count,
        commenter_count: 0,
        comment_count: 0,
        parent_content_id: nil,
        content_id: event.id,
        parent_content_type: nil,
        event_instance_id: event.channel.next_or_first_instance.id,
        parent_event_instance_id: nil,
        registration_deadline: nil,
        created_at: event.created_at.iso8601,
        updated_at: event.updated_at.iso8601,
        event_id: event.channel.id,
        cost: event.channel.cost,
        sold: nil,
        avatar_url: event.created_by.avatar_url,
        organization_profile_image_url: nil,
        biz_feed_public: event.biz_feed_public?,
        sunset_date: event.sunset_date.try(:iso8601),
        images: event.images.map do |image|
            {
              id: image.id,
              image_url: image.image.url,
              primary: (image.primary? ? 1 : 0),
              width: image.width,
              height: image.height,
              file_extension: image.file_extension
            }
          end,
        can_edit: false,
        event_instances: event.channel.event_instances.map do |ei|
          {
            id: ei.id,
            subtitle: ei.subtitle_override,
            starts_at: ei.start_date.try(:iso8601),
            ends_at: ei.end_date.try(:iso8601),
            presenter_name: ei.presenter_name
          }
        end,
        content_origin: 'ugc',
        split_content: a_hash_including({
          head: an_instance_of(String),
          tail: an_instance_of(String)
        }),
        cost_type: event.channel.cost_type,
        contact_phone: event.channel.contact_phone,
        contact_email: event.channel.contact_email,
        venue_name: event.channel.venue.name,
        venue_address: event.channel.venue.address,
        venue_city: event.channel.venue.city,
        venue_state: event.channel.venue.state,
        venue_zip: event.channel.venue.zip,
        venue_url: event.channel.venue.venue_url,
        content_locations: event.content_locations.map do |cl|
          {
            id: cl.id,
            location_id: cl.location.slug,
            location_type: cl.location_type,
            location_name: cl.location.name
          }
        end
      })
    end

    it 'returns market content in expected format' do
      get "/api/v3/contents", {}, headers
      serialized_market = response_json[:contents].find{|i| i[:content_type] == 'market'}

      expect(serialized_market).to include({
        id: market.id,
        title: market.title,
        image_url: market.images[0].url,
        author_id: market.created_by.id,
        author_name: market.author_name,
        content_type: 'market',
        organization_id: org.id,
        organization_name: org.name,
        subtitle: market.subtitle,
        published_at: market.pubdate.iso8601,
        starts_at: nil,
        ends_at: nil,
        content: market.sanitized_content,
        view_count: market.view_count,
        commenter_count: 0,
        comment_count: 0,
        parent_content_id: nil,
        content_id: market.id,
        parent_content_type: nil,
        parent_event_instance_id: nil,
        registration_deadline: nil,
        created_at: market.created_at.iso8601,
        updated_at: market.updated_at.iso8601,
        event_id: nil,
        cost: market.channel.cost,
        sold: market.channel.sold,
        avatar_url: market.created_by.avatar_url,
        organization_profile_image_url: nil,
        biz_feed_public: market.biz_feed_public?,
        sunset_date: market.sunset_date.try(:iso8601),
        images: market.images.map do |image|
            {
              id: image.id,
              image_url: image.image.url,
              primary: (image.primary? ? 1 : 0),
              width: image.width,
              height: image.height,
              file_extension: image.file_extension
            }
          end,
        can_edit: false,
        event_instances: nil,
        content_origin: 'ugc',
        split_content: a_hash_including({
          head: an_instance_of(String),
          tail: an_instance_of(String)
        }),
        cost_type: nil,
        contact_phone: market.channel.contact_phone,
        contact_email: market.channel.contact_email,
        venue_zip: nil,
        venue_url: nil,
        content_locations: market.content_locations.map do |cl|
          {
            id: cl.id,
            location_id: cl.location.slug,
            location_type: cl.location_type,
            location_name: cl.location.name
          }
        end
      })
    end

    context "when no user logged in" do
      subject { get "/api/v3/contents", {}, headers }

      it "returns content in standard categories but NOT talk" do
        subject
        expect(response_json[:contents].length).to eq 3
      end
    end

    context "when user logged in", skip: true do
      pending "This section needs fixed, because the api is not returning talk (bug)"

      subject { get "/api/v3/contents", {}, headers.merge(auth_headers) }

      it "returns content in standard categories, including Talk for user location, but NOT comments" do
        subject
        expect(response_json[:contents].length).to eq 4
      end

      it 'returns talk content in expected format' do
        subject
        serialized_talk = response_json[:contents].find{|i| i[:content_type] == 'talk'}

        expect(serialized_talk).to include({
          id: talk.id,
          title: talk.title,
          image_url: talk.images[0].url,
          author_id: talk.created_by.id,
          author_name: talk.author_name,
          content_type: 'talk',
          organization_id: org.id,
          organization_name: org.name,
          subtitle: talk.subtitle,
          venue_zip: nil,
          published_at: talk.pubdate.iso8601,
          starts_at: nil,
          ends_at: nil,
          content: talk.sanitized_content,
          view_count: talk.view_count,
          commenter_count: 0,
          comment_count: 0,
          parent_content_id: nil,
          content_id: talk.id,
          parent_content_type: nil,
          event_instance_id: nil,
          parent_event_instance_id: nil,
          registration_deadline: nil,
          created_at: talk.created_at.iso8601,
          updated_at: talk.updated_at.iso8601,
          event_id: nil,
          cost: nil,
          sold: nil,
          avatar_url: talk.created_by.avatar_url,
          organization_profile_image_url: nil,
          biz_feed_public: talk.biz_feed_public?,
          sunset_date: talk.sunset_date.try(:iso8601),
          images: talk.images.map do |image|
              {
                id: image.id,
                image_url: image.image.url,
                primary: (image.primary? ? 1 : 0),
                width: image.width,
                height: image.height,
                file_extension: image.file_extension
              }
            end,
          can_edit: true,
          event_instances: nil,
          content_origin: 'ugc',
          split_content: a_hash_including({
            head: an_instance_of(String),
            tail: an_instance_of(String)
          }),
          cost_type: nil,
          contact_phone: nil,
          contact_email: nil,
          venue_url: nil,
          content_locations: talk.content_locations.map do |cl|
            {
              id: cl.id,
              location_id: cl.location.slug,
              location_type: cl.location_type,
              location_name: cl.location.name
            }
          end
        })
      end
    end

    context "when 'query' parameter is present" do
      before do
        @market_post = FactoryGirl.create :content, :market_post, title: news.title, organization: org, published: true
      end

      it 'returns items from all categories matching the query' do
        get "/api/v3/contents", { query: news.title }, auth_headers
        expect(response_json[:contents].length).to eq 2
      end
    end

  end

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
  end

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
