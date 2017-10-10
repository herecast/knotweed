require 'spec_helper'



describe 'Contents Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/contents', elasticsearch: true do
    shared_examples_for 'JSON schema for all Content' do
      it 'has the expected fields for all content' do
        do_request

        expect(subject).to include({
          id: content.id,
          title: content.title,
          image_url: content.images[0].url,
          author_id: content.created_by.id,
          author_name: content.author_name,
          content_type: content.content_type.to_s,
          organization_id: org.id,
          organization_name: org.name,
          subtitle: content.subtitle,
          published_at: content.pubdate.iso8601,
          content: content.sanitized_content,
          view_count: content.view_count,
          commenter_count: content.commenter_count,
          comment_count: content.comment_count,
          comments: content.comments.map do |comment|
              {
                id: comment.channel.try(:id) || comment.id,
                content_id: comment.id,
                title: comment.sanitized_title,
                content: comment.sanitized_content,
                parent_content_id: comment.parent_id,
                published_at: comment.pubdate.iso8601,
                user_id: comment.created_by.try(:id),
                user_name: comment.created_by.try(:name),
                user_image_url: comment.created_by.try(:avatar).try(:url)
              }
          end,
          parent_content_id: nil,
          content_id: content.id,
          parent_content_type: nil,
          created_at: content.created_at.iso8601,
          updated_at: content.updated_at.iso8601,
          avatar_url: content.created_by.avatar_url,
          organization_profile_image_url: nil,
          biz_feed_public: content.biz_feed_public?,
          sunset_date: content.sunset_date.try(:iso8601),
          images: content.images.map do |image|
              {
                id: image.id,
                image_url: image.image.url,
                primary: (image.primary? ? 1 : 0),
                width: image.width,
                height: image.height,
                file_extension: image.file_extension,
                caption: image.caption
              }
            end,
          can_edit: be(true).or(be(false)),
          content_origin: 'ugc',
          split_content: a_hash_including({
            head: an_instance_of(String),
            tail: an_instance_of(String)
          }),
          content_locations: content.content_locations.map do |cl|
            {
              id: cl.id,
              location_id: cl.location.slug,
              location_type: cl.location_type,
              location_name: cl.location.name
            }
          end
        })
      end

      context 'when comments exist' do
        let!(:comments) {
          content.children = FactoryGirl.create_list :content, 7, :comment,
          created_by: FactoryGirl.create(:user),
          parent: content
        }

        it 'embeds the last 6 comments' do
          do_request
          expect(subject).to include({
            comments: comments.sort_by(&:pubdate).reverse.take(6).map do |comment|
              {
                id: comment.channel.try(:id) || comment.id,
                content_id: comment.id,
                title: comment.sanitized_title,
                content: comment.sanitized_content,
                parent_content_id: comment.parent_id,
                published_at: comment.pubdate.iso8601,
                user_id: comment.created_by.id,
                user_name: comment.created_by.name,
                user_image_url: comment.created_by.avatar.url
              }
            end
          })
        end
      end

    end

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
      FactoryGirl.create :content, :comment, organization: org,
        published: true, parent_id: talk.id
    }

    context 'news content' do
      let(:do_request) {
        get "/api/v3/contents", {}, headers
      }

      subject {
        response_json[:contents].find{|i| i[:content_type] == 'news'}
      }

      it_behaves_like 'JSON schema for all Content' do
        let(:content) { news }
      end
    end

    context 'event content' do
      let(:do_request) {
        get "/api/v3/contents", {}, headers
      }

      subject {
        response_json[:contents].find{|i| i[:content_type] == 'event'}
      }

      it_behaves_like 'JSON schema for all Content' do
        let(:content) { event }
      end

      it 'additional event related fields' do
        do_request
        expect(subject).to include({
          starts_at: event.channel.next_or_first_instance.start_date.try(:iso8601),
          ends_at: event.channel.next_or_first_instance.end_date.try(:iso8601),
          event_instance_id: event.channel.next_or_first_instance.id,
          parent_event_instance_id: nil,
          registration_deadline: nil,
          event_id: event.channel.id,
          cost: event.channel.cost,
          event_instances: event.channel.event_instances.map do |ei|
            {
              id: ei.id,
              subtitle: ei.subtitle_override,
              starts_at: ei.start_date.try(:iso8601),
              ends_at: ei.end_date.try(:iso8601),
              presenter_name: ei.presenter_name
            }
          end,
          contact_phone: event.channel.contact_phone,
          contact_email: event.channel.contact_email,
          venue_name: event.channel.venue.name,
          venue_address: event.channel.venue.address,
          venue_city: event.channel.venue.city,
          venue_state: event.channel.venue.state,
          venue_zip: event.channel.venue.zip,
          venue_url: event.channel.venue.venue_url,
        })

      end
    end

    context 'market content' do
      let(:do_request) {
        get "/api/v3/contents", {}, headers
      }

      subject {
        response_json[:contents].find{|i| i[:content_type] == 'market'}
      }

      it_behaves_like 'JSON schema for all Content' do
        let(:content) { market }
      end

      it 'has additional market related fields' do
        do_request
        expect(subject).to include({
          cost: market.channel.cost,
          sold: market.channel.sold,
          contact_phone: market.channel.contact_phone,
          contact_email: market.channel.contact_email,
        })
      end
    end

    context "when no user logged in" do
      before do
        get "/api/v3/contents", {}, headers
      end

      it "returns content in standard categories but NOT talk" do
        expect(response_json[:contents].length).to eq 3
      end
    end

    context "when user logged in" do
      context 'returning talk content' do
        let(:do_request) {
          get "/api/v3/contents", {}, headers.merge(auth_headers)
        }

        subject {
          response_json[:contents].find{|i| i[:content_type] == 'talk'}
        }

        it_behaves_like 'JSON schema for all Content' do
          let(:content) { talk.reload }
        end
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

    context 'content_type parameter' do
      [:market_post, :news, :event, :talk].each do |content_type|
        describe "?content_type=#{content_type}" do
          before do
            get "/api/v3/contents", {
              content_type: content_type
            }, headers
          end

          it "returns only #{content_type} content" do
            content_types = response_json[:contents].map do |data|
              data[:content_type]
            end

            expect(content_types).to all eql content_type.to_s
          end
        end
      end
    end

    context "when radius param == 'me'" do
      before do
        @owning_user = FactoryGirl.create :user
        FactoryGirl.create :content, :news,
          created_by: @owning_user,
          organization: org,
          published: true
      end

      context "when no user logged in" do
        subject { get "/api/v3/contents", { radius: 'me' } }

        it "returns only current user's content" do
          subject
          expect(response).to have_http_status :ok
          expect(response_json[:contents].length).to eq 0
        end
      end

      context "when user logged in" do
        subject { get "/api/v3/contents", { radius: 'me' }, headers.merge(auth_headers_for(@owning_user)) }

        it "returns only current user's content" do
          subject
          expect(response_json[:contents].length).to eq 1
        end
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
