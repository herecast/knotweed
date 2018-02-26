require 'rails_helper'

describe 'Feed endpoints', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/feed', elasticsearch: true do
    shared_examples_for 'JSON schema for all Content' do
      it 'has the expected fields for all content' do
        do_request

        expect(subject).to include({
          id: content.id,
          author_id: content.created_by.id,
          author_name: content.author_name,
          avatar_url: content.created_by.avatar_url,
          base_location_ids: content.base_locations.map(&:id),
          biz_feed_public: content.biz_feed_public,
          campaign_end: content.ad_campaign_end,
          campaign_start: content.ad_campaign_start,
          click_count: an_instance_of(Fixnum).or(be_nil),
          comment_count: an_instance_of(Fixnum).or(be_nil),
          commenter_count: an_instance_of(Fixnum).or(be_nil),
          comments: content.comments.map do |comment|
              {
                id: comment.channel.try(:id) || comment.id,
                content: comment.sanitized_content,
                content_id: comment.id,
                parent_content_id: comment.parent_id,
                published_at: comment.pubdate.iso8601,
                title: comment.sanitized_title,
                user_id: comment.created_by.try(:id),
                user_image_url: comment.created_by.try(:avatar).try(:url),
                user_name: comment.created_by.try(:name),
              }
          end,
          contact_email: an_instance_of(String).or(be_nil),
          contact_phone: an_instance_of(String).or(be_nil),
          content: content.sanitized_content,
          content_origin: 'ugc',
          content_type: content.content_type.to_s,
          cost: an_instance_of(String).or(be_nil),
          cost_type: an_instance_of(String).or(be_nil),
          created_at: content.created_at.iso8601,
          embedded_ad: content.embedded_ad?,
          ends_at: an_instance_of(String).or(be_nil),
          event_url: an_instance_of(String).or(be_nil),
          event_instance_id: an_instance_of(Fixnum).or(be_nil),
          event_instances: an_instance_of(Array).or(be_nil),
          images: content.images.map do |image|
            {
              id: image.id,
              caption: image.caption,
              content_id: image.imageable_id,
              file_extension: image.file_extension,
              height: image.height,
              image_url: image.image.url,
              position: image.position,
              primary: image.primary?,
              width: image.width
            }
          end,
          image_url: content.images[0].url,
          organization_biz_feed_active: org.biz_feed_active,
          organization_id: org.id,
          organization_name: org.name,
          organization_profile_image_url: nil,

          # @TODO: parent fields should be revisited, do we need them?
          parent_content_id: content.parent_id,
          parent_content_type: content.parent.try(:content_type),
          parent_event_instance_id: an_instance_of(Fixnum).or(be_nil),

          promote_radius: content.promote_radius,
          published_at: content.pubdate.iso8601,
          redirect_url: an_instance_of(String).or(be_nil),
          registration_deadline: an_instance_of(String).or(be_nil),
          schedules: an_instance_of(Array).or(be_nil),
          sold: content.channel.try(:sold),
          split_content: a_hash_including({
            head: an_instance_of(String),
            tail: an_instance_of(String)
          }),
          starts_at: an_instance_of(String).or(be_nil),
          subtitle: content.subtitle,
          sunset_date: content.sunset_date.try(:iso8601),
          title: content.sanitized_title,
          location_id: content.base_locations.map(&:slug).first,
          updated_at: content.updated_at.iso8601,
          venue_address: an_instance_of(String).or(be_nil),
          venue_city: an_instance_of(String).or(be_nil),
          venue_name: an_instance_of(String).or(be_nil),
          venue_state: an_instance_of(String).or(be_nil),
          venue_url: an_instance_of(String).or(be_nil),
          venue_zip: an_instance_of(String).or(be_nil),
          view_count: content.view_count
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
        get "/api/v3/feed", {}, headers
      }

      subject {
        response_json[:feed_items].find{|i| i[:content][:content_type] == 'news'}[:content]
      }

      it_behaves_like 'JSON schema for all Content' do
        let(:content) { news }
      end
    end

    context 'event content' do
      let(:do_request) {
        get "/api/v3/feed", {}, headers
      }

      subject {
        response_json[:feed_items].find{|i| i[:content][:content_type] == 'event'}[:content]
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
        get "/api/v3/feed", {}, headers
      }

      subject {
        response_json[:feed_items].find{|i| i[:content][:content_type] == 'market'}[:content]
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
        get "/api/v3/feed", {}, headers
      end

      it "returns content in standard categories including talk" do
        expect(response_json[:feed_items].length).to eq 4
      end
    end

    context "when user logged in" do
      context 'returning talk content' do
        let(:do_request) {
          get "/api/v3/feed", {}, headers.merge(auth_headers)
        }

        subject {
          response_json[:feed_items].find{|i| i[:content][:content_type] == 'talk'}[:content]
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

      subject { get "/api/v3/feed", {}, headers.merge(auth_headers) }

      it "returns feed_items including listserv carousel" do
        expect(Carousels::ListservCarousel).to receive(:new)
        subject
      end
    end

    context "page param > 1" do
      subject { get "/api/v3/feed?page=2", {}, headers.merge(auth_headers) }

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
        @archived_business = FactoryGirl.create :organization, name: "#{news.title} 3",
          org_type: 'Business',
          archived: true
        @archived_publisher = FactoryGirl.create :organization, name: "#{news.title} 4",
          org_type: 'Blog',
          archived: true
      end

      subject { get "/api/v3/feed", { query: news.title }, auth_headers }

      it 'returns items from all categories matching the query' do
        subject
        contents = response_json[:feed_items].select{ |i| i[:model_type] == 'content'}
        expect(contents.length).to eq 2
      end

      it "returns two Organization collections" do
        subject
        collections = response_json[:feed_items].select{ |i| i[:model_type] == 'carousel'}
        expect(collections.length).to eq 2
      end

      it "does not return archived businesses" do
        subject
        carousels = response_json[:feed_items].select{ |i| i[:model_type] == 'carousel' }
        business_carousel = carousels.find{ |c| c[:carousel][:title] == 'Businesses' }
        expect(business_carousel[:carousel][:organizations].map{ |o| o[:id] }).not_to include @archived_business.id
      end

      it "does not return archived publishers" do
        subject
        carousels = response_json[:feed_items].select{ |i| i[:model_type] == 'carousel' }
        business_carousel = carousels.find{ |c| c[:carousel][:title] == 'Publishers' }
        expect(business_carousel[:carousel][:organizations].map{ |o| o[:id] }).not_to include @archived_publisher.id
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
            get "/api/v3/feed", {
              content_type: content_type
            }, headers
          end

          it "returns only #{content_type} content" do
            content_types = response_json[:feed_items].map do |data|
              data[:content][:content_type]
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

        subject { get "/api/v3/feed?content_type=listserv", {}, headers }

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
        subject { get "/api/v3/feed", { radius: 'myStuff' } }

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
        subject { get "/api/v3/feed", { radius: 'myStuff' }, headers.merge(auth_headers_for(@owning_user)) }

        it "returns only current user's content" do
          subject
          expect(response_json[:feed_items].length).to eq 1
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
      get "/api/v3/feed?organization_id=#{@organization.id}"
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
        expect(response_json[:feed_items][0][:content][:id]).to eq @event.content.id
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
        expect(response_json[:feed_items][0][:content][:id]).to eq @tagged_content.id
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
        expect(response_json[:feed_items][0][:content][:id]).to eq @market_post.id
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
        expect(response_json[:feed_items][0][:content][:id]).to eq @event.id
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
        expect(response_json[:feed_items][0][:content][:id]).to eq @talk.id
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
        expect(response_json[:feed_items][0][:content][:id]).to eq @news.id
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
        get "/api/v3/feed?organization_id=#{@inactive_organization.id}"
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
          get "/api/v3/feed?organization_id=#{@organization.id}&show=everything"
          Timecop.return
        end

        it "returns drafts, hidden content and regular content" do
          subject
          expect(response_json[:feed_items].length).to eq 4
        end
      end

      describe "?show=hidden" do
        subject do
          Timecop.travel(Time.current + 1.day)
          get "/api/v3/feed?organization_id=#{@organization.id}&show=hidden"
          Timecop.return
        end

        it "returns biz_feed_public: false contents" do
          subject
          expect(response_json[:feed_items].length).to eq 1
          expect(response_json[:feed_items][0][:content][:id]).to eq @hidden_content.id
        end
      end

      describe "?show=drafts" do
        subject do
          Timecop.travel(Time.current + 1.day)
          get "/api/v3/feed?organization_id=#{@organization.id}&show=draft"
          Timecop.return
        end

        it "returns drafts and scheduled posts only" do
          subject
          expect(response_json[:feed_items].length).to eq 2
          content_ids = response_json[:feed_items].map { |c| c[:content][:id] }
          expect(content_ids).to match_array [@draft_content.id, @scheduled_content.id]
        end
      end
    end
  end
end
