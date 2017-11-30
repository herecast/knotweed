require 'rails_helper';

def serialized_event_instance(event_instance)
{
  author_id: event_instance.event.content.created_by.try(:id),
  author_name: event_instance.event.content.created_by.try(:name),
  avatar_url: event_instance.event.content.created_by.try(:avatar_url),
  can_edit: be(true).or(be(false)),
  comment_count: 0,
  comments: [],
  contact_email: event_instance.event.contact_email,
  contact_phone: event_instance.event.contact_phone,
  content: event_instance.event.content.sanitized_content,
  content_id: event_instance.event.content.id,
  content_locations: [],
  cost: event_instance.event.cost,
  cost_type: event_instance.event.cost_type,
  ends_at: event_instance.end_date.try(:iso8601),
  event_id: event_instance.event.id,
  event_instances: [],
  id: event_instance.id,
  image_file_extension: event_instance.event.content.images.first.try(:image).try(:file_extension),
  image_height: event_instance.event.content.images.first.try(:image).try(:height),
  image_url: event_instance.event.content.images.first.try(:image).try(:url),
  image_width: event_instance.event.content.images.first.try(:image).try(:width),
  organization_biz_feed_active: event_instance.event.content.organization.try(:biz_feed_active),
  organization_id: event_instance.event.content.organization_id,
  organization_name: event_instance.event.content.organization.try(:name),
  organization_profile_image_url: event_instance.event.content.organization.try(:profile_image_url) || event_instance.event.content.organization.try(:logo_url),
  presenter_name: event_instance.presenter_name,
  published_at: event_instance.event.content.pubdate.iso8601,
  registration_deadline: event_instance.event.registration_deadline.try(:iso8601),
  starts_at: event_instance.start_date.iso8601,
  subtitle: event_instance.subtitle_override,
  title: event_instance.event.content.title,
  updated_at: event_instance.updated_at.try(:iso8601),
  venue_address: event_instance.event.venue.try(:address),
  venue_city: event_instance.event.venue.try(:city),
  venue_latitude: event_instance.event.venue.try(:latitude),
  venue_locate_name: event_instance.event.venue.try(:geocoding_address),
  venue_longitude: event_instance.event.venue.try(:longitude),
  venue_name: event_instance.event.venue.try(:name),
  venue_state: event_instance.event.venue.try(:state),
  venue_url: event_instance.event.venue.try(:url),
  venue_zip: event_instance.event.venue.try(:zip),
}
end

describe 'Event Instance endpoints', type: :request do
  describe 'GET /api/v3/event_instances', elasticsearch: true do
    let!(:event_instance) {
      FactoryGirl.create(:event_instance,
                         published: true)
    }

    subject {
      get '/api/v3/event_instances'
      response.body
    }

    it 'returns expected schema fields' do
      expect(subject).to include_json({
        event_instances: [serialized_event_instance(event_instance.reload)]
      })
    end
  end

  describe 'GET /api/v3/event_instances/:id' do
    let!(:event_instance) {
      FactoryGirl.create(:event_instance,
                         published: true)
    }

    subject {
      get "/api/v3/event_instances/#{event_instance.id}"
      response.body
    }

    it 'returns expected schema fields' do
      expect(subject).to include_json({
        event_instance: serialized_event_instance(event_instance)
      })
    end
  end

  describe '/event_instances/active_dates', elasticsearch: true do
    context 'Given instances in in different days, in future' do
      before do
        FactoryGirl.create(:event_instance,
          published: true,
          start_date: 1.day.from_now
        )

        FactoryGirl.create_list(:event_instance, 3,
          start_date: 3.days.from_now,
          published: true
        )
      end

      subject {
        get '/api/v3/event_instances/active_dates'
      }

      it 'returns the dates and count of events corresponding' do
        subject
        expect(response.body).to include_json({
          active_dates: [
            {
              date: 1.day.from_now.strftime('%Y-%m-%d'),
              count: 1
            },
            {
              date: 3.days.from_now.strftime('%Y-%m-%d'),
              count: 3
            }
          ]
        })
      end
    end

    describe 'filtering by date range' do
      let(:start_date) {
        1.day.ago.to_date
      }

      let(:end_date) {
        1.day.from_now.to_date
      }

      subject {
        get '/api/v3/event_instances/active_dates', {
          start_date: start_date,
          end_date: end_date
        }
      }

      let!(:instance_within_range) {
        FactoryGirl.create :event_instance,
          published: true,
          start_date: Date.current
      }

      let!(:instance_out_of_range) {
        FactoryGirl.create :event_instance,
          published: true,
          start_date: 3.days.from_now
      }

      it 'returns only data for range' do
        subject
        expect(response.body).to eql({active_dates: [
            {
              date: Date.current,
              count: 1
            }
        ]}.to_json)
      end
    end

    describe 'location filtering' do
      let(:location) {
        FactoryGirl.create :location
      }

      let(:radius) { 10 }

      subject {
        get '/api/v3/event_instances/active_dates', {
          location_id: location.slug,
          radius: radius
        }
      }

      before do
        @event = FactoryGirl.create(:event,
          published: true,
          locations: [
            FactoryGirl.create(:location,
              coordinates: Geocoder::Calculations.random_point_near(
                location,
                radius, units: :mi
              )
            )
          ]
        )
        @event_instance_within_radius = @event.event_instances.first

        @event2 = FactoryGirl.create(:event,
          published: true,
          locations: [
            FactoryGirl.create(:location,
              coordinates: [0,0]
            )
          ]
        )
        @event_instance_out_of_radius = @event.event_instances.first
      end

      it 'returns instances that are within filtered radius' do
        subject
        expect(response.body).to eql({active_dates: [
            {
              date: @event_instance_within_radius.start_date.strftime('%Y-%m-%d'),
              count: 1
            }
        ]}.to_json)
      end
    end
  end
end
