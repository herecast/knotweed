# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile metrics' do
  let(:remote_ip) { '1.1.1.1' }
  let(:user_agent) { 'AmigaVoyager/3.4.4 (MorphOS/PPC native)' }
  let(:location) { FactoryGirl.create :location, slug: 'newton-nh' }

  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(remote_ip)
    allow_any_instance_of(ActionDispatch::Request).to receive(:user_agent).and_return(user_agent)
  end

  describe 'POST /api/v3/metrics/profiles/:organization_id' do
    let(:content) do
      FactoryGirl.create :content, pubdate: (Time.zone.now - 1.day)
    end

    let(:organization) { FactoryGirl.create :organization }

    subject do
      post "/api/v3/metrics/profiles/#{organization.id}",
           params: context_data
    end

    let(:context_data) do
      {
        content_id: content.id,
        client_id: '1222kk898943',
        location_id: location.slug,
        event_type: 'click'
      }
    end

    it 'records profile metric impression' do
      expect { subject }.to change {
        ProfileMetric.count
      }.by(1)

      record = ProfileMetric.last

      expect(record.event_type).to eql 'click'
      expect(record.organization).to eql organization
      expect(record.user_agent).to eql user_agent
      expect(record.user_ip).to eql remote_ip
      expect(record.location).to eql location
      expect(record.client_id).to eql context_data[:client_id]
    end

    it 'responds with 201' do
      subject
      expect(response.status).to eql 201
    end

    context 'for event_type `impression`' do
      let(:context_data) do
        {
          client_id: '1222kk898943',
          location_id: location.slug,
          event_type: 'impression'
        }
      end

      it 'records profile metric impression' do
        expect { subject }.to change {
          ProfileMetric.count
        }.by(1)

        record = ProfileMetric.last

        expect(record.event_type).to eql 'impression'
        expect(record.organization).to eql organization
        expect(record.user_agent).to eql user_agent
        expect(record.user_ip).to eql remote_ip
        expect(record.location).to eql location
        expect(record.client_id).to eql context_data[:client_id]
      end
    end

    context 'for unpublished content' do
      let(:content) { FactoryGirl.create :content, pubdate: nil }

      it 'responds with 200' do
        subject
        expect(response.status).to eql 200
      end

      it 'does not record a profile metric impression' do
        expect { subject }.to_not change { ProfileMetric.count }
      end
    end

    context 'for future scheduled content' do
      let(:content) { FactoryGirl.create :content, pubdate: 1.week.from_now }

      it 'responds with 200' do
        subject
        expect(response.status).to eql 200
      end

      it 'does not record a profile metric impression' do
        expect { subject }.to_not change { ProfileMetric.count }
      end
    end

    context 'content_id not included' do
      before do
        context_data.delete(:content_id)
      end

      it 'responds with 422' do
        subject
        expect(response.status).to eql 422
      end
    end
  end
end
