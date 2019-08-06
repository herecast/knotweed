# frozen_string_literal: true

require 'rails_helper'

describe 'Feed endpoints', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/feed?content_type=calendar&start_date=', elasticsearch: true do
    context 'when date filters passed' do
      before do
          @past_event = FactoryGirl.create(:event_instance, start_date: 3.days.ago)
          @future_event = FactoryGirl.create(:event_instance, start_date: 1.day.from_now)
          @current_event = FactoryGirl.create(:event_instance, start_date: Time.current + 1.minute)
      end

      context 'when start_date is passed' do
        subject do
          get '/api/v3/feed',
            params: { start_date: Date.current, content_type: 'calendar' },
            headers: headers
        end

        it 'returns events on or after the start date' do
          subject
          result_ids = response_json[:feed_items].map{ |i| i[:content][:id] }
          expected_ids = [
            @future_event.event.content.id, @current_event.event.content.id
          ]
          expect(result_ids).to match_array expected_ids
        end
      end

      context 'when end_date is passed' do
        subject do
          get '/api/v3/feed',
            params: { end_date: Time.current + 1.minute, content_type: 'calendar' },
            headers: headers
        end

        it 'should limit results by the end date' do
          subject
          result_ids = response_json[:feed_items].map{ |i| i[:content][:id] }
          expected_id = [@current_event.event.content.id]
          expect(result_ids).to match_array(expected_id)
        end
      end
    end
  end

  describe 'GET /api/v3/feed', elasticsearch: true do
    shared_examples_for 'JSON schema for all Content' do
      it 'has the expected fields for all content' do
        do_request

        expect(subject).to include(
          id: content.id,
          author_id: content.created_by.id,
          author_name: content.author_name,
          avatar_url: content.created_by.avatar_url,
          biz_feed_public: content.biz_feed_public,
          campaign_end: content.ad_campaign_end,
          campaign_start: content.ad_campaign_start,
          click_count: an_instance_of(Integer).or(be_nil),
          comment_count: an_instance_of(Integer).or(be_nil),
          commenter_count: an_instance_of(Integer).or(be_nil),
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
                        user_name: comment.created_by.try(:name)
                      }
                    end,
          contact_email: an_instance_of(String).or(be_nil),
          contact_phone: an_instance_of(String).or(be_nil),
          content: ImageUrlService.optimize_image_urls(
            html_text: content.sanitized_content,
            default_width:  600,
            default_height: 1800,
            default_crop:   false
          ),
          content_origin: 'ugc',
          content_type: content.content_type.to_s,
          cost: an_instance_of(String).or(be_nil),
          cost_type: an_instance_of(String).or(be_nil),
          created_at: content.created_at.iso8601,
          embedded_ad: content.embedded_ad?,
          ends_at: an_instance_of(String).or(be_nil),
          event_url: an_instance_of(String).or(be_nil),
          event_instance_id: an_instance_of(Integer).or(be_nil),
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
          organization: {
            id: org.id,
            name: org.name,
            profile_image_url: org.profile_image_url || org.logo_url,
            biz_feed_active: !!org.biz_feed_active,
            description: org.description,
            city: org.business_locations&.first&.city,
            state: org.business_locations&.first&.state,
            active_subscriber_count: org.active_subscriber_count
          },
          organization_id: org.id,
          organization_name: org.name,

          # @TODO: parent fields should be revisited, do we need them?
          parent_content_id: content.parent_id,
          parent_content_type: content.parent.try(:content_type),
          parent_event_instance_id: an_instance_of(Integer).or(be_nil),

          promote_radius: content.promote_radius,
          published_at: content.pubdate.iso8601,
          redirect_url: an_instance_of(String).or(be_nil),
          registration_deadline: an_instance_of(String).or(be_nil),
          schedules: an_instance_of(Array).or(be_nil),
          sold: content.channel.try(:sold),
          starts_at: an_instance_of(String).or(be_nil),
          subtitle: content.subtitle,
          sunset_date: content.sunset_date.try(:iso8601),
          title: content.sanitized_title,
          location: {
            id: content.location.id,
            city: content.location.city,
            state: content.location.state,
            latitude: content.location.latitude,
            longitude: content.location.longitude,
            image_url: content.location.image_url
          },
          updated_at: content.updated_at.iso8601,
          venue_address: an_instance_of(String).or(be_nil),
          venue_city: an_instance_of(String).or(be_nil),
          venue_name: an_instance_of(String).or(be_nil),
          venue_state: an_instance_of(String).or(be_nil),
          venue_url: an_instance_of(String).or(be_nil),
          venue_zip: an_instance_of(String).or(be_nil),
          view_count: content.view_count
        )
      end

      context 'when comments exist' do
        let!(:comments) do
          content.children = FactoryGirl.create_list :content, 7, :comment,
                                                     created_by: FactoryGirl.create(:user),
                                                     parent: content
        end

        it 'embeds the last 6 comments' do
          do_request
          expect(subject).to include(
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
          )
        end
      end
    end

    let(:org) { FactoryGirl.create :organization }
    let(:headers) { { 'ACCEPT' => 'application/json' } }

    let(:locations) do
      FactoryGirl.create_list(:location, 2)
    end
    let(:user) do
      FactoryGirl.create(:user)
    end
    let!(:news) do
      FactoryGirl.create :content, :news,
                         created_by: user,
                         organization: org,
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
    end
    let!(:event) do
      FactoryGirl.create :content, :event,
                         created_by: user,
                         organization: org,
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
    end
    let!(:market) do
      FactoryGirl.create :content, :market_post,
                         created_by: user,
                         organization: org,
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
    end
    let!(:talk) do
      FactoryGirl.create :content, :talk,
                         created_by: user,
                         organization: org,
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
    end
    let!(:comment) do
      FactoryGirl.create :content, :comment, organization: org,
                                             parent_id: talk.id
    end

    context 'news content' do
      let(:do_request) do
        get '/api/v3/feed', params: {}, headers: headers
      end

      subject do
        response_json[:feed_items].find { |i| i[:content][:content_type] == 'news' }[:content]
      end

      it_behaves_like 'JSON schema for all Content' do
        let(:content) { news }
      end
    end

    context 'event content' do
      let(:do_request) do
        get '/api/v3/feed', params: {}, headers: headers
      end

      subject do
        response_json[:feed_items].find { |i| i[:content][:content_type] == 'event' }[:content]
      end

      it_behaves_like 'JSON schema for all Content' do
        let(:content) { event }
      end

      it 'additional event related fields' do
        do_request
        expect(subject).to include(
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
          venue_url: event.channel.venue.venue_url
        )
      end
    end

    context 'market content' do
      let(:do_request) do
        get '/api/v3/feed', params: {}, headers: headers
      end

      subject do
        response_json[:feed_items].find { |i| i[:content][:content_type] == 'market' }[:content]
      end

      it_behaves_like 'JSON schema for all Content' do
        let(:content) { market }
      end

      it 'has additional market related fields' do
        do_request
        expect(subject).to include(
          cost: market.channel.cost,
          sold: market.channel.sold,
          contact_phone: market.channel.contact_phone,
          contact_email: market.channel.contact_email
        )
      end
    end

    context 'when no user logged in' do
      before do
        get '/api/v3/feed', params: {}, headers: headers
      end

      it 'returns content in standard categories including talk' do
        expect(response_json[:feed_items].length).to eq 4
      end
    end

    context 'when content has future latest_activity' do
      before do
        content = FactoryGirl.create :content, :news
        content.update_attribute(:latest_activity, 3.days.from_now)
      end

      subject { get '/api/v3/feed', params: {}, headers: headers }

      it 'does not not return content' do
        subject
        expect(response_json[:feed_items].length).to eq 4
      end
    end

    context 'when user logged in' do
      context 'returning talk content' do
        let(:do_request) do
          get '/api/v3/feed', params: {}, headers: headers.merge(auth_headers)
        end

        subject do
          response_json[:feed_items].find { |i| i[:content][:content_type] == 'talk' }[:content]
        end

        it_behaves_like 'JSON schema for all Content' do
          let(:content) { talk.reload }
        end
      end
    end

    context 'when user has blocked orgs' do
      before do
        organization = FactoryGirl.create :organization
        @content = FactoryGirl.create :content, :news,
                                      organization_id: organization.id,
                                      location_id: user.location_id
        FactoryGirl.create :organization_hide,
                           organization_id: organization.id,
                           user_id: user.id
      end

      subject { get '/api/v3/feed', params: {}, headers: headers.merge(auth_headers) }

      it 'does not return blocked Org content' do
        subject
        returned_ids = response_json[:feed_items].map { |i| i[:content][:id] }
        expect(returned_ids).not_to include @content.id
      end
    end

    context "when 'query' parameter is present" do
      before do
        @market_post = FactoryGirl.create :content, :market_post,
                                          title: news.title,
                                          organization: org,
                                          location_id: user.location_id
        @organization = FactoryGirl.create :organization,
                                           name: news.title,
                                           org_type: 'Business'
        @second_organization = FactoryGirl.create :organization,
                                                  name: "#{news.title} 2",
                                                  org_type: 'Blog',
                                                  can_publish_news: true
        @archived_business = FactoryGirl.create :organization,
                                                name: "#{news.title} 3",
                                                org_type: 'Business',
                                                archived: true,
                                                can_publish_news: true
        @archived_publisher = FactoryGirl.create :organization,
                                                 name: "#{news.title} 4",
                                                 org_type: 'Blog',
                                                 archived: true,
                                                 can_publish_news: true
      end

      subject { get '/api/v3/feed', params: { query: news.title }, headers: auth_headers }

      it 'returns items from all categories matching the query' do
        subject
        contents = response_json[:feed_items].select { |i| i[:model_type] == 'content' }
        expect(contents.length).to eq 2
      end

      it 'returns one Organization collection' do
        subject
        collections = response_json[:feed_items].select { |i| i[:model_type] == 'carousel' }
        expect(collections.length).to eq 1
      end

      it 'does not return archived orgs' do
        subject
        carousel = response_json[:feed_items].select { |i| i[:model_type] == 'carousel' }[0]
        expect(carousel[:carousel][:organizations].map { |o| o[:id] }).not_to include @archived_publisher.id
      end

      context 'when one carousel returns no Organizations' do
        before do
          @second_organization.update_attribute(:name, 'non-search')
        end

        it 'call only returns carousel with Organizations' do
          subject
          collections = response_json[:feed_items].select { |i| i[:model_type] == 'carousel' }
          expect(collections.length).to eq 0
        end
      end
    end

    context 'content_type parameter' do
      %i[market_post news event talk].each do |content_type|
        describe "?content_type=#{content_type}" do
          before do
            get '/api/v3/feed', params: {
              content_type: content_type
            }, headers: headers
          end

          it "returns only #{content_type} content" do
            content_types = response_json[:feed_items].map do |data|
              data[:content][:content_type]
            end

            expect(content_types).to all eql content_type.to_s
          end
        end
      end
    end
  end

  describe 'organization_id param present', elasticsearch: true do
    before do
      @organization = FactoryGirl.create :organization
      @other_organization = FactoryGirl.create :organization
    end

    subject do
      Timecop.travel(Time.current + 1.day)
      get "/api/v3/feed?organization_id=#{@organization.id}"
      Timecop.return
    end

    context 'when Organization has tagged Content' do
      before do
        @tagged_content = FactoryGirl.create :content, :market_post
        FactoryGirl.create :content, :market_post, organization_id: @other_organization.id
        @organization.tagged_contents << @tagged_content
      end

      it 'returns tagged Content' do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:content][:id]).to eq @tagged_content.id
      end
    end

    context 'when Organization content is outside of location range' do
      before do
        distant_location = FactoryGirl.create :location
        @close_location = FactoryGirl.create :location,
                                             location_ids_within_fifty_miles: []
        @distant_org_item = FactoryGirl.create :content, :market_post,
                                               organization_id: @organization.id,
                                               location_id: distant_location.id
      end

      subject { get "/api/v3/feed?organization_id=#{@organization.id}&location_id=#{@close_location.id}" }

      it 'returns content' do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:content][:id]).to eq @distant_org_item.id
      end
    end

    context 'when Organization owns Market Posts' do
      before do
        @market_post = FactoryGirl.create :content, :market_post, organization_id: @organization.id
        FactoryGirl.create :content, :market_post, organization_id: @other_organization.id
      end

      it 'returns the Market Posts' do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:content][:id]).to eq @market_post.id
      end
    end

    context 'when Organization owns Events' do
      before do
        @event = FactoryGirl.create :content, :event, organization_id: @organization.id
        FactoryGirl.create :content, :event, organization_id: @other_organization.id
      end

      it 'returns the Events' do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:content][:id]).to eq @event.id
      end
    end

    context 'when Organization owns Content in talk category' do
      before do
        @talk = FactoryGirl.create :content, :talk, organization_id: @organization.id
        FactoryGirl.create :content, :talk, organization_id: @other_organization.id
      end

      it 'returns talk items' do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:content][:id]).to eq @talk.id
      end
    end

    context 'when Organization owns Content in news category' do
      before do
        @news = FactoryGirl.create :content, :news, organization_id: @organization.id
        FactoryGirl.create :content, :news, organization_id: @other_organization.id
      end

      it 'returns news items' do
        subject
        expect(response_json[:feed_items].length).to eq 1
        expect(response_json[:feed_items][0][:content][:id]).to eq @news.id
      end
    end

    context 'when Content is created but has no pubdate' do
      before do
        content = FactoryGirl.create :content, :news,
                                     organization_id: @organization.id
        content.update_attribute(:pubdate, nil)
      end

      it 'does not return nil pubdate items' do
        subject
        expect(response_json[:feed_items].length).to eq 0
      end
    end

    context 'when Content is scheduled for future release' do
      before do
        content = FactoryGirl.create :content, :news,
                                     organization_id: @organization.id,
                                     pubdate: Date.current + 5.days
      end

      it 'it does not return future pubdate items' do
        subject
        expect(response_json[:feed_items].length).to eq 0
      end
    end

    context 'when Campaign present and biz_feed_public: true' do
      before do
        @campaign_content = FactoryGirl.create :content, :campaign,
                                               organization_id: @organization.id
        @campaign_content.update_attribute :biz_feed_public, true
      end

      it 'appears' do
        subject
        expect(response_json[:feed_items].length).to eq 1
      end
    end

    context 'when Organization is type: Business and biz feed inactive' do
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

      it 'it returns empty payload' do
        subject
        expect(response_json[:feed_items].length).to eq 0
      end
    end

    context 'when content_type is calendar' do
      before do
        @news = FactoryGirl.create :content, :news,
                                   organization_id: @organization.id,
                                   biz_feed_public: true
        @first_event = FactoryGirl.create :content, :event,
                                          organization_id: @organization.id,
                                          biz_feed_public: true
        @second_event = FactoryGirl.create :content, :event,
                                           organization_id: @organization.id,
                                           biz_feed_public: true
        @second_event.channel.event_instances[0].update_attribute(
          :start_date, 1.month.from_now
        )
      end

      subject { get "/api/v3/feed?organization_id=#{@organization.id}&content_type=calendar" }

      it 'returns only events, in chronological order' do
        subject
        expect(response_json[:feed_items].length).to eq 2
        expect(response_json[:feed_items][0][:content][:id]).to eq @first_event.id
      end

      context 'when Event is tagged to organization' do
        before do
          alt_org = FactoryGirl.create :organization
          @tagged_event = FactoryGirl.create :content, :event,
                                             organization_id: alt_org.id,
                                             biz_feed_public: true
          @organization.tagged_contents << @tagged_event
        end

        it 'returns tagged event as well' do
          subject
          ids = response_json[:feed_items].map { |i| i[:content][:id] }
          expect(ids).to include @tagged_event.id
        end
      end
    end

    describe 'additional params' do
      before do
        @organization = FactoryGirl.create :organization
        @hidden_content = FactoryGirl.create :content, :news,
                                             biz_feed_public: false,
                                             organization_id: @organization.id,
                                             location_id: user.location_id
        @draft_content = FactoryGirl.create :content, :news,
                                            organization_id: @organization.id,
                                            location_id: user.location_id
        @draft_content.update_attribute(:pubdate, nil)
        @regular_content = FactoryGirl.create :content, :news,
                                              biz_feed_public: true,
                                              organization_id: @organization.id,
                                              location_id: user.location_id
        @scheduled_content = FactoryGirl.create :content, :news,
                                                organization_id: @organization.id,
                                                pubdate: 3.days.from_now,
                                                location_id: user.location_id
        @event = FactoryGirl.create :content, :event,
                                    organization_id: @organization.id,
                                    biz_feed_public: true,
                                    location_id: user.location_id
        Timecop.travel(Time.current + 1.day)
      end

      after do
        Timecop.return
      end

      describe '?show=everything' do
        subject { get "/api/v3/feed?organization_id=#{@organization.id}&show=everything" }

        it 'returns drafts, hidden content and regular content' do
          subject
          expect(response_json[:feed_items].length).to eq 5
        end

        context 'when Campaign present and biz_feed_public: false' do
          before do
            @campaign_content = FactoryGirl.create :content, :campaign,
                                                   organization_id: @organization.id,
                                                   biz_feed_public: false
          end

          it 'appears' do
            subject
            expect(response_json[:feed_items].length).to eq 6
          end
        end

        context 'when Campaign present and biz_feed_public: true' do
          before do
            @campaign_content = FactoryGirl.create :content, :campaign,
                                                   organization_id: @organization.id,
                                                   biz_feed_public: true
          end

          it 'appears' do
            subject
            expect(response_json[:feed_items].length).to eq 6
          end
        end
      end

      describe '?show=hidden' do
        subject { get "/api/v3/feed?organization_id=#{@organization.id}&show=hidden" }

        it 'returns biz_feed_public: false contents' do
          subject
          expect(response_json[:feed_items].length).to eq 1
          expect(response_json[:feed_items][0][:content][:id]).to eq @hidden_content.id
        end

        context 'when Campaign present and biz_feed_public: false' do
          before do
            @campaign_content = FactoryGirl.create :content, :campaign,
                                                   organization_id: @organization.id,
                                                   biz_feed_public: false
          end

          it 'appears' do
            subject
            expect(response_json[:feed_items].length).to eq 2
          end
        end

        context 'when Campaign present and biz_feed_public: true' do
          before do
            @campaign_content = FactoryGirl.create :content, :campaign,
                                                   organization_id: @organization.id
            @campaign_content.update_attribute :biz_feed_public, true
          end

          it 'does not appear' do
            subject
            expect(response_json[:feed_items].length).to eq 1
          end
        end
      end

      describe '?show=drafts' do
        subject { get "/api/v3/feed?organization_id=#{@organization.id}&show=draft" }

        it 'returns drafts and scheduled posts only' do
          subject
          expect(response_json[:feed_items].length).to eq 2
          content_ids = response_json[:feed_items].map { |c| c[:content][:id] }
          expect(content_ids).to match_array [@draft_content.id, @scheduled_content.id]
        end

        context 'when Campaign present and biz_feed_public: false' do
          before do
            @campaign_content = FactoryGirl.create :content, :campaign,
                                                   organization_id: @organization.id,
                                                   biz_feed_public: false
          end

          it 'does not appear' do
            subject
            expect(response_json[:feed_items].length).to eq 2
          end
        end

        context 'when Campaign present and biz_feed_public: true' do
          before do
            @campaign_content = FactoryGirl.create :content, :campaign,
                                                   organization_id: @organization.id
            @campaign_content.update_attribute :biz_feed_public, true
          end

          it 'does not appear' do
            subject
            expect(response_json[:feed_items].length).to eq 2
          end
        end
      end

      describe '?calendar=false' do
        subject { get "/api/v3/feed?organization_id=#{@organization.id}&calendar=false" }

        it 'returns all but events' do
          subject
          expect(response_json[:feed_items].length).to eq 1
          expect(response_json[:feed_items][0][:content][:id]).not_to eq @event.id
        end
      end
    end
  end
end
