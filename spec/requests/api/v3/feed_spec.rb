# frozen_string_literal: true

require 'rails_helper'

describe 'Feed endpoints', type: :request do
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
          biz_feed_public: content.biz_feed_public,
          campaign_end: content.ad_campaign_end,
          campaign_start: content.ad_campaign_start,
          click_count: an_instance_of(Integer).or(be_nil),
          comment_count: an_instance_of(Integer).or(be_nil),
          commenter_count: an_instance_of(Integer).or(be_nil),
          comments: content.comments.map do |comment|
                      {
                        id: comment.id,
                        content_id: comment.id,
                        content: comment.sanitized_content,
                        parent_id: comment.content_id,
                        published_at: comment.pubdate.iso8601,
                        pubdate: comment.pubdate.iso8601,
                        caster_id: comment.created_by.try(:id),
                        caster_handle: comment.created_by.try(:handle),
                        caster_name: comment.created_by.try(:name),
                        caster_avatar_image_url: comment.created_by.try(:avatar).try(:url),
                        title: content.title
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
          FactoryGirl.create_list :comment, 7, created_by: FactoryGirl.create(:user),
            content: content
        end

        it 'embeds all comments' do
          do_request
          expected_results = comments.sort_by(&:pubdate).reverse.map do |comment|
            {
              id: comment.id,
              content_id: comment.id,
              content: comment.sanitized_content,
              parent_id: comment.content_id,
              published_at: comment.pubdate.iso8601,
              pubdate: comment.pubdate.iso8601,
              caster_id: comment.created_by.try(:id),
              caster_handle: comment.created_by.try(:handle),
              caster_name: comment.created_by.try(:name),
              caster_avatar_image_url: comment.created_by.try(:avatar).try(:url),
              title: content.title
            }
          end
          expect(subject[:comments]).to match_array(expected_results)
        end
      end
    end

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
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
    end
    let!(:event) do
      FactoryGirl.create :content, :event,
                         created_by: user,
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
    end
    let!(:market) do
      FactoryGirl.create :content, :market_post,
                         created_by: user,
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
    end
    let!(:talk) do
      FactoryGirl.create :content, :talk,
                         created_by: user,
                         location_id: user.location_id,
                         images: [FactoryGirl.build(:image, :primary)]
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
        get '/api/v3/feed?content_type=market', params: {}, headers: headers
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

      it 'returns events, news, talk' do
        expect(response_json[:feed_items].length).to eq 3
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
        expect(response_json[:feed_items].length).to eq 3
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

    context 'when user has blocked Casters' do
      before do
        caster = FactoryGirl.create :caster
        @blocked_content = FactoryGirl.create :content, :news,
                                      created_by_id: caster.id,
                                      location_id: user.location_id
        FactoryGirl.create :caster_hide,
                           user_id: user.id,
                           caster_id: caster.id
      end

      subject { get '/api/v3/feed', params: {}, headers: headers.merge(auth_headers) }

      it 'does not return blocked Caster content' do
        subject
        returned_ids = response_json[:feed_items].map { |i| i[:content][:id] }
        expect(returned_ids).not_to include @blocked_content.id
      end
    end

    context "when 'query' parameter is present" do
      before do
        @market_post = FactoryGirl.create :content, :market_post,
                                          title: news.title,
                                          location_id: user.location_id
      end

      subject { get '/api/v3/feed', params: { query: news.title }, headers: auth_headers }

      it 'returns items from all categories matching the query' do
        subject
        contents = response_json[:feed_items].select { |i| i[:model_type] == 'content' }
        expect(contents.length).to eq 2
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
end
