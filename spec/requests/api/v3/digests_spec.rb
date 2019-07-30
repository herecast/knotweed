# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Digest API Endpoints', type: :request do
  describe 'GET /api/v3/digests' do
    context 'when listservs are active' do
      let!(:digests) { FactoryGirl.create_list :listserv, 3, display_subscribe: true, active: true }

      it 'returns available listserv digests' do
        get '/api/v3/digests'
        expect(response_json[:digests].count).to eq digests.count

        response_json[:digests].each do |digest|
          expect(digest).to include(:id, :digest_description, :name, :digest_send_time, :digest_send_day)
        end
      end
    end

    context 'when listservs are not active' do
      let!(:inactive_digest) { FactoryGirl.create :listserv, active: false, display_subscribe: true }
      let!(:active_digest) { FactoryGirl.create :listserv, active: true, display_subscribe: true }

      it 'does not return the listserv digests where `display_subscribe` is false' do
        get '/api/v3/digests'
        expect(response_json[:digests].count).to eq 1
      end
    end
  end

  describe 'GET /api/v3/digests/:id' do
    context 'when given an id of a listserv record' do
      let!(:digest) { FactoryGirl.create :listserv }

      subject { get "/api/v3/digests/#{digest.id}" }

      it 'returns expected json output' do
        subject
        expect(response_json[:digest]).to match(
          id: digest.id,
          digest_description: digest.digest_description,
          name: digest.name,
          digest_send_time: digest.digest_send_time.strftime('%l:%M %p').strip,
          digest_send_day: digest.digest_send_day,
          next_digest_send_time: digest.next_digest_send_time.iso8601
        )
      end
    end
  end
end
