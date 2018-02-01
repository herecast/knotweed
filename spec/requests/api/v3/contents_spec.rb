require 'spec_helper'



describe 'Contents Endpoints', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
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
          biz_feed_public: content.biz_feed_public,
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
          content_origin: 'ugc',
          campaign_start: content.ad_campaign_start,
          campaign_end: content.ad_campaign_end,
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
        response_json[:feed_items].find{|i| i[:feed_content][:content_type] == 'news'}[:feed_content]
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
        response_json[:feed_items].find{|i| i[:feed_content][:content_type] == 'event'}[:feed_content]
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
        response_json[:feed_items].find{|i| i[:feed_content][:content_type] == 'market'}[:feed_content]
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

      it "returns content in standard categories including talk" do
        expect(response_json[:feed_items].length).to eq 4
      end
    end

    context "when user logged in" do
      context 'returning talk content' do
        let(:do_request) {
          get "/api/v3/contents", {}, headers.merge(auth_headers)
        }

        subject {
          response_json[:feed_items].find{|i| i[:feed_content][:content_type] == 'talk'}[:feed_content]
        }

        it_behaves_like 'JSON schema for all Content' do
          let(:content) { talk.reload }
        end
      end
    end

    context "when first page and no query" do
      before do
        allow(Carousels::ListservCarousel).to receive(:new).and_return(
          Carousels::ListservCarousel.new
        )
      end

      subject { get "/api/v3/contents", {}, headers.merge(auth_headers) }

      it "returns feed_items including listserv carousel" do
        expect(Carousels::ListservCarousel).to receive(:new)
        subject
      end
    end

    context "page param > 1" do
      subject { get "/api/v3/contents?page=2", {}, headers.merge(auth_headers) }

      it "does not make call to Carousels::ListservCarousel" do
        expect(Carousels::ListservCarousel).not_to receive(:new)
        subject
      end
    end

    context "when 'query' parameter is present" do
      before do
        @market_post = FactoryGirl.create :content, :market_post, title: news.title, organization: org, published: true
        @organization = FactoryGirl.create :organization, name: news.title, org_type: 'Business'
        @second_organization = FactoryGirl.create :organization, name: "#{news.title} 2", org_type: 'Blog'
      end

      subject { get "/api/v3/contents", { query: news.title }, auth_headers }

      it 'returns items from all categories matching the query' do
        subject
        feed_contents = response_json[:feed_items].select{ |i| i[:model_type] == 'feed_content'}
        expect(feed_contents.length).to eq 2
      end

      it "returns two Organization collections" do
        subject
        collections = response_json[:feed_items].select{ |i| i[:model_type] == 'carousel'}
        expect(collections.length).to eq 2
      end

      it "does not call to Carousels::ListservCarousel" do
        expect(Carousels::ListservCarousel).not_to receive(:new)
      end

      context "when one carousel returns no Organizations" do
        before do
          @second_organization.update_attribute(:name, 'non-search')
        end

        it "call only returns carousel with Organizations" do
          subject
          collections = response_json[:feed_items].select{ |i| i[:model_type] == 'carousel'}
          expect(collections.length).to eq 1
        end
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
            content_types = response_json[:feed_items].map do |data|
              data[:feed_content][:content_type]
            end

            expect(content_types).to all eql content_type.to_s
          end

          it "does not make call to Carousels::ListservCarousel" do
            expect(Carousels::ListservCarousel).not_to receive(:new)
          end
        end
      end

      context "when content_type: listserv" do
        before do
          @listserv = Organization.find_by(name: 'Listserv')
          @listserv.update_attribute(:id, Organization::LISTSERV_ORG_ID)
          # @listserv = FactoryGirl.create :organization, name: 'Listserv'
          @listserv_content = FactoryGirl.create :content, :talk,
            organization_id: Organization::LISTSERV_ORG_ID,
            raw_content: 'What follows is the biography of Luke Skywalker'
        end

        subject { get "/api/v3/contents?content_type=listserv", {}, headers }

        it "returns only listserv content" do
          subject
          expect(response_json[:feed_items].length).to eq 1
          expect(response_json[:feed_items][0][:id]).to eq @listserv_content.id
        end
      end
    end

    context "when radius param == 'myStuff'" do
      before do
        @owning_user = FactoryGirl.create :user
        FactoryGirl.create :content, :news,
          created_by: @owning_user,
          organization: org,
          published: true
      end

      context "when no user logged in" do
        subject { get "/api/v3/contents", { radius: 'myStuff' } }

        it "returns only current user's content" do
          subject
          expect(response).to have_http_status :ok
          expect(response_json[:feed_items].length).to eq 0
        end

        it "does not call to Carousels::ListservCarousel" do
          expect(Carousels::ListservCarousel).not_to receive(:new)
          subject
        end
      end

      context "when user logged in" do
        subject { get "/api/v3/contents", { radius: 'myStuff' }, headers.merge(auth_headers_for(@owning_user)) }

        it "returns only current user's content" do
          subject
          expect(response_json[:feed_items].length).to eq 1
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

  describe "organization_id param present", elasticsearch: true do
    before do
      @organization = FactoryGirl.create :organization
      @other_organization = FactoryGirl.create :organization
    end

    subject do
      Timecop.travel(Time.current + 1.day)
      get "/api/v3/contents?organization_id=#{@organization.id}"
      Timecop.return
    end

    context 'when Organization has BusinessLocation with Events' do
      before do
        business_location = FactoryGirl.create :business_location
        @organization.business_locations << business_location
        @event = FactoryGirl.create :event, venue_id: business_location.id
        FactoryGirl.create :content, :market_post, organization_id: @other_organization.id
      end

      it "returns Events" do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:feed_content][:id]).to eq @event.content.id
      end
    end

    context "when Organization has tagged Content" do
      before do
        @tagged_content = FactoryGirl.create :content, :market_post
        FactoryGirl.create :content, :market_post, organization_id: @other_organization.id
        @organization.tagged_contents << @tagged_content
      end

      it "returns tagged Content" do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:feed_content][:id]).to eq @tagged_content.id
      end
    end

    context "when Organization owns Market Posts" do
      before do
        @market_post = FactoryGirl.create :content, :market_post, organization_id: @organization.id
        FactoryGirl.create :content, :market_post, organization_id: @other_organization.id
      end

      it "returns the Market Posts" do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:feed_content][:id]).to eq @market_post.id
      end
    end

    context "when Organization owns Events" do
      before do
        @event = FactoryGirl.create :content, :event, organization_id: @organization.id
        FactoryGirl.create :content, :event, organization_id: @other_organization.id
      end

      it "returns the Events" do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:feed_content][:id]).to eq @event.id
      end
    end

    context "when Organization owns Content in talk category" do
      before do
        @talk = FactoryGirl.create :content, :talk, organization_id: @organization.id
        FactoryGirl.create :content, :talk, organization_id: @other_organization.id
      end

      it "returns talk items" do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:feed_content][:id]).to eq @talk.id
      end
    end

    context "when Organization owns Content in news category" do
      before do
        @news = FactoryGirl.create :content, :news, organization_id: @organization.id
        FactoryGirl.create :content, :news, organization_id: @other_organization.id
      end

      it "returns news items" do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:feed_content][:id]).to eq @news.id
      end
    end

    context "when Content is created but has no pubdate" do
      before do
        content = FactoryGirl.create :content, :news,
          organization_id: @organization.id
        content.update_attribute(:pubdate, nil)
      end

      it "does not return nil pubdate items" do
        subject
        expect(response_json[:feed_items].length).to eq 0
      end
    end

    context "when Content is scheduled for future release" do
      before do
        content = FactoryGirl.create :content, :news,
          organization_id: @organization.id,
          pubdate: Date.current + 5.days
      end

      it "it does not return future pubdate items" do
        subject
        expect(response_json[:feed_items].length).to eq 0
      end
    end

    context "when Organization is type: Business and biz feed inactive" do
      before do
        @inactive_organization = FactoryGirl.create :organization,
          org_type: 'Business',
          biz_feed_active: false
        FactoryGirl.create :content, :news,
          organization_id: @inactive_organization.id,
          biz_feed_public: true
      end

      subject do
        Timecop.travel(Time.current + 1.day)
        get "/api/v3/contents?organization_id=#{@inactive_organization.id}"
        Timecop.return
      end

      it "it returns empty payload" do
        subject
        expect(response_json[:feed_items].length).to eq 0
      end
    end

    describe "additional params" do
      before do
        @organization = FactoryGirl.create :organization
        @hidden_content = FactoryGirl.create :content, :news,
          biz_feed_public: false,
          organization_id: @organization.id
        @draft_content = FactoryGirl.create :content, :news,
          organization_id: @organization.id
        @draft_content.update_attribute(:pubdate, nil)
        @regular_content = FactoryGirl.create :content, :news,
          biz_feed_public: true,
          organization_id: @organization.id
        @scheduled_content = FactoryGirl.create :content, :news,
          organization_id: @organization.id,
          pubdate: 3.days.from_now
      end

      describe "?show=everything" do
        subject do
          Timecop.travel(Time.current + 1.day)
          get "/api/v3/contents?organization_id=#{@organization.id}&show=everything"
          Timecop.return
        end

        it "returns drafts, scheduled content, hidden content and regular content" do
          subject
          expect(response_json[:feed_items].length).to eq 4
        end
      end

      describe "?show=hidden" do
        subject do
          Timecop.travel(Time.current + 1.day)
          get "/api/v3/contents?organization_id=#{@organization.id}&show=hidden"
          Timecop.return
        end

        it "returns biz_feed_public: false contents" do
          subject
          expect(response_json[:feed_items].length).to eq 1
          expect(response_json[:feed_items][0][:feed_content][:id]).to eq @hidden_content.id
        end
      end

      describe "?show=drafts" do
        subject do
          Timecop.travel(Time.current + 1.day)
          get "/api/v3/contents?organization_id=#{@organization.id}&show=draft"
          Timecop.return
        end

        it "returns drafts and scheduled posts only" do
          subject
          expect(response_json[:feed_items].length).to eq 2
          content_ids = response_json[:feed_items].map { |c| c[:feed_content][:id] }
          expect(content_ids).to match_array [@draft_content.id, @scheduled_content.id]
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
