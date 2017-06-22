require 'spec_helper'

describe 'Events Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }
  let(:consumer_app) { FactoryGirl.create :consumer_app }

  describe 'events index', elasticsearch: true do
    let!(:non_default_location_event) {
      FactoryGirl.create :event,
        locations: [FactoryGirl.create(:location)]
    }

    before do
      @location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @event = FactoryGirl.create :event, locations: [@location]

      ContentCategory.first.update_attribute(:name, 'event')
      consumer_app.organizations << @event.content.organization
      consumer_app.organizations << non_default_location_event.content.organization
      Content.searchkick_index.refresh
    end

    let(:headers) { {
      'ACCEPT' => 'application/json',
      'Consumer-App-Uri' => consumer_app.uri
    } }

    subject { get "/api/v3/events", {}, headers }

    it "returns events" do
      subject
      expect(response_json).to match(
        events: [
          a_hash_including({
            id: @event.content.id,
            title: @event.content.title,
            image_url: nil,
            author_name: be_a(String),
            content_type: 'event',
            organization_id: @event.content.organization.id,
            organization_name: @event.content.organization.name,
            venue_name: @event.venue.name,
            venue_address: @event.venue.try(:address),
            venue_city: @event.venue.city,
            venue_state: @event.venue.state,
            published_at: @event.content.pubdate.try(:iso8601),
            starts_at: @event.event_instances.first.start_date.try(:iso8601),
            ends_at: @event.event_instances.first.end_date.try(:iso8601),
            content: be_a(String),
            view_count: @event.content.view_count,
            commenter_count: @event.content.commenter_count,
            comment_count: @event.content.comment_count,
            parent_content_id: @event.content.parent_id,
            content_id: @event.content.id,
            parent_content_type: nil,
            event_instance_id: @event.event_instances.first.id,
            parent_event_instance_id: nil,
            registration_deadline: @event.registration_deadline
          })
        ]
      )
    end

    context 'without location_id specified' do
      it 'returns events from default location' do
        subject
        event_ids = response_json[:events].map{|attrs| attrs[:id]}
        expect(event_ids).to include @event.content.id
        expect(event_ids).to_not include non_default_location_event.content.id
      end
    end

    context 'with location_id specified' do
      it 'returns events from specified location only' do
        get "/api/v3/events", {
          location_id: non_default_location_event.content.location_ids.first
        }, headers

        event_ids = response_json[:events].map{|attrs| attrs[:id]}

        #expect(event_ids).to_not include @event.id
        expect(event_ids).to include non_default_location_event.content.id
      end

      context 'location_id is a slug' do
        it 'returns events from specified location only' do
          get "/api/v3/events", {
            location_id: non_default_location_event.content.locations.first.slug
          }, headers

          event_ids = response_json[:events].map{|attrs| attrs[:id]}

          #expect(event_ids).to_not include @event.id
          expect(event_ids).to include non_default_location_event.content.id
        end
      end
    end
  end

  describe 'can_edit' do
    let(:schedule) { FactoryGirl.create :schedule }
    let(:event) { FactoryGirl.create :event }

    context 'when ability allows for edit' do
      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, event.content).and_return(true)
      end

      it "returns true" do
        get "/api/v3/events/#{event.id}"
        expect(response_json[:event][:can_edit]).to eql true
      end
    end

    context 'when ability does not allow to edit' do
      let(:put_params) do
        {
          title: 'blerb',
          content: Faker::Lorem.paragraph,
        }
      end

      it "returns false" do
        allow_any_instance_of(Ability).to receive(:can?).with(:manage, event.content).and_return(false)
        get "/api/v3/events/#{event.id}"
        expect(response_json[:event][:can_edit]).to eql false
      end

      it 'does not allow a user to send an update' do
        put "/api/v3/events/#{schedule.event.id}", { event: put_params }, auth_headers
        expect(response.status).to eql 403
      end
      
    end
  end
end
