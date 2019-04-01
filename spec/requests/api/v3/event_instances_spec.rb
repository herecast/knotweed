# frozen_string_literal: true

require 'rails_helper'

def serialized_event_instance(event_instance)
  {
    author_id: event_instance.event.content.created_by.try(:id),
    author_name: event_instance.event.content.created_by.try(:name),
    avatar_url: event_instance.event.content.created_by.try(:avatar_url),
    comments: [],
    comment_count: 0,
    commenter_count: 0,
    contact_email: event_instance.event.contact_email,
    contact_phone: event_instance.event.contact_phone,
    content: event_instance.event.content.sanitized_content,
    content_id: event_instance.event.content.id,
    content_origin: an_instance_of(String),
    cost: event_instance.event.cost,
    cost_type: event_instance.event.cost_type,
    created_at: event_instance.event.content.created_at.iso8601,
    ends_at: event_instance.end_date.try(:iso8601),
    event_id: event_instance.event.id,
    event_instances: [],
    ical_url: an_instance_of(String).or(be_nil),
    id: event_instance.id,
    images: [],
    image_url: event_instance.event.content.images.first.try(:image).try(:url),
    location_id: event_instance.event.content.location_id,
    organization_biz_feed_active: event_instance.event.content.organization.try(:biz_feed_active),
    organization_id: event_instance.event.content.organization_id,
    organization_name: event_instance.event.content.organization.try(:name),
    organization_profile_image_url: event_instance.event.content.organization.try(:profile_image_url) || event_instance.event.content.organization.try(:logo_url),
    presenter_name: event_instance.presenter_name,
    promote_radius: event_instance.event.content.promote_radius,
    published_at: event_instance.event.content.pubdate.iso8601,
    registration_deadline: event_instance.event.registration_deadline.try(:iso8601),
    starts_at: event_instance.start_date.iso8601,
    subtitle: event_instance.subtitle_override,
    title: event_instance.event.content.title,
    updated_at: event_instance.updated_at.try(:iso8601),
    url: event_instance.event.event_url,
    venue_address: event_instance.event.venue.try(:address),
    venue_city: event_instance.event.venue.try(:city),
    venue_latitude: event_instance.event.venue.try(:latitude),
    venue_longitude: event_instance.event.venue.try(:longitude),
    venue_name: event_instance.event.venue.try(:name),
    venue_state: event_instance.event.venue.try(:state),
    venue_url: event_instance.event.venue.try(:url),
    venue_zip: event_instance.event.venue.try(:zip)
  }
end

describe 'Event Instance endpoints', type: :request do
  describe 'GET /api/v3/event_instances', elasticsearch: true do
    let!(:event_instance) { FactoryGirl.create(:event_instance) }

    subject do
      get '/api/v3/event_instances'
      response.body
    end

    it 'returns expected schema fields' do
      expect(subject).to include_json(
        event_instances: [serialized_event_instance(event_instance.reload)]
      )
    end

    context 'when a comment is removed' do
      before do
        FactoryGirl.create :content, :comment,
                           parent_id: event_instance.event.content.id,
                           deleted_at: Time.current
        @allowed_comment = FactoryGirl.create :content, :comment,
                                              parent_id: event_instance.event.content.id,
                                              deleted_at: nil
      end

      it 'is not returned with event instance' do
        returned_event = JSON.parse(subject)['event_instances'][0]
        expect(returned_event['comments'].length).to eq 1
        expect(returned_event['comments'][0]['id']).to eq @allowed_comment.channel.id
      end
    end
  end

  describe 'GET /api/v3/event_instances/:id' do
    let!(:event_instance) { FactoryGirl.create(:event_instance) }

    subject do
      get "/api/v3/event_instances/#{event_instance.id}"
      response.body
    end

    it 'returns expected schema fields' do
      expect(subject).to include_json(
        event_instance: serialized_event_instance(event_instance)
      )
    end
  end

  describe '/event_instances/active_dates', elasticsearch: true do
    context 'Given instances in in different days, in future' do
      before do
        FactoryGirl.create(:event_instance, start_date: 1.day.from_now)

        FactoryGirl.create_list(:event_instance, 3,
                                start_date: 3.days.from_now)
      end

      subject do
        get '/api/v3/event_instances/active_dates'
      end

      it 'returns the dates and count of events corresponding' do
        subject
        expect(response.body).to include_json(
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
        )
      end
    end

    describe 'filtering by date range' do
      let(:start_date) do
        1.day.ago.to_date
      end

      let(:end_date) do
        1.day.from_now.to_date
      end

      subject do
        get '/api/v3/event_instances/active_dates', params: {
          start_date: start_date,
          end_date: end_date
        }
      end

      let!(:instance_within_range) { FactoryGirl.create :event_instance, start_date: Date.current }

      let!(:instance_out_of_range) { FactoryGirl.create :event_instance, start_date: 3.days.from_now }

      it 'returns only data for range' do
        subject
        expect(response.body).to eql({ active_dates: [
          {
            date: Date.current,
            count: 1
          }
        ] }.to_json)
      end
    end
  end

  describe 'GET /api/v3/event_instances/sitemap_ids' do
    let!(:org) { FactoryGirl.create :organization }
    let!(:alt_org) { FactoryGirl.create :organization }

    let!(:instance1) do
      FactoryGirl.create :event_instance
    end
    let!(:instance2) do
      FactoryGirl.create :event_instance
    end

    before do
      instance1.event.content.update organization: org
      instance2.event.content.update organization: org
    end

    subject do
      get '/api/v3/event_instances/sitemap_ids'
      response_json
    end

    it 'returns expected id, and content_ids for each record' do
      expect(subject[:instances]).to include({
                                               id: instance1.id,
                                               content_id: instance1.event.content.id
                                             },
                                             id: instance2.id,
                                             content_id: instance2.event.content.id)
    end

    it 'does not include instance if content is listerv' do
      instance1.event.content.update organization_id: Organization::LISTSERV_ORG_ID
      ids = subject[:instances].map { |d| d[:id] }
      expect(ids).to_not include instance1.id
    end

    it 'does not include instance if content is removed' do
      instance1.event.content.update removed: true
      ids = subject[:instances].map { |d| d[:id] }
      expect(ids).to_not include instance1.id
    end

    it 'does not include instance if content pubdate is null' do
      instance1.event.content.update pubdate: nil
      ids = subject[:instances].map { |d| d[:id] }
      expect(ids).to_not include instance1.id
    end

    it 'does not include instance if content pubdate is in the future' do
      instance1.event.content.update pubdate: Time.zone.now.tomorrow
      ids = subject[:instances].map { |d| d[:id] }
      expect(ids).to_not include instance1.id
    end
  end
end
