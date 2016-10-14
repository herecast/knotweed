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
      let!(:digests) { FactoryGirl.create_list :listserv, 3 }
      let!(:active_digest) { FactoryGirl.create :listserv, active: true, display_subscribe: true }
      before do
        digests.each { |digest| digest.update_attributes(active: false, post_email: Faker::Internet.email)}
      end

      it 'does not return the listserv digests where `display_subscribe` is false' do
        get '/api/v3/digests'
        expect(response_json[:digests].count).to eq 1
      end
    end
  end
end

