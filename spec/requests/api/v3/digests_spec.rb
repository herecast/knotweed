require 'rails_helper'

RSpec.describe 'Digest API Endpoints', type: :request do
  describe 'GET /api/v3/digests' do
    context 'when listservs are active and `is_managed_list?`' do
      let!(:digests) { FactoryGirl.create_list :listserv, 3, display_subscribe: true }
      before do
        digests.each {|digest| digest.update_attributes(subscribe_email: Faker::Internet.email) }
      end
      it 'returns available listserv digests' do
        get '/api/v3/digests'
        expect(response_json[:digests].count).to eq digests.count

        response_json[:digests].each do |digest|
          expect(digest).to include(:id, :digest_description, :name, :digest_send_time, :digest_send_day)
        end
      end
    end

    context 'when listservs are not active or `is_managed_list`' do
      FactoryGirl.create :subtext_listserv
      FactoryGirl.create :vc_listserv
      # listserv factory defaults to list_type: 'custom digest'
      let!(:digests) { FactoryGirl.create_list :listserv, 3, list_type: 'internal_digest' }
      let!(:active_digest) { FactoryGirl.create :listserv, active: true, display_subscribe: true }
      before do
        digests.each { |digest| digest.update_attributes(active: false, post_email: Faker::Internet.email)}
      end

      it 'does not return the listserv digests where `display_subscribe` is false and `list_type` is custom_digest' do
        get '/api/v3/digests'
        expect(response_json[:digests].count).to eq 1
      end
    end
  end

  describe 'GET /api/v3/digests/:id' do
    context 'when given an id of a listserv record' do
      let!(:digest) { FactoryGirl.create :listserv, :custom_digest }

      subject { get "/api/v3/digests/#{digest.id}" }

      it 'returns expected json output' do
        subject
        expect(response_json[:digest]).to match({
          id: digest.id,
          digest_description: digest.digest_description,
          name: digest.name,
          digest_send_time: digest.digest_send_time.strftime('%l:%M %p').strip,
          digest_send_day: digest.digest_send_day,
          next_digest_send_time: digest.next_digest_send_time.iso8601
        })
      end
    end
  end
end

