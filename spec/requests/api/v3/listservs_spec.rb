require 'rails_helper'

RSpec.describe 'Listserv API Endpoints', type: :request do
  describe 'GET /api/v3/listservs' do
    context 'when listservs exist;' do
      let!(:listservs) { FactoryGirl.create_list :vc_listserv, 3, display_subscribe: true }
      it 'returns them' do
        get '/api/v3/listservs'
        expect(response_json[:listservs].count).to eql listservs.count

        response_json[:listservs].each do |ls|
          expect(ls).to include(:id, :name)
        end
      end

      context 'given ids[]= parameter' do
        it 'returns the specified listservs' do
          subset = listservs.slice(0,2)
          get '/api/v3/listservs', ids: subset.collect(&:id)
          returned_ids = response_json[:listservs].collect{|l| l[:id]}
          expect(returned_ids).to match_array subset.collect(&:id)
        end
      end
    end
  end

  describe 'GET /api/v3/listservs/:id' do
    context 'when listserv exists' do
      let!(:listserv) { FactoryGirl.create :vc_listserv }

      it 'returns the listserv' do
        get "/api/v3/listservs/#{listserv.id}"
        expect(response_json[:listserv]).to match({
          id: listserv.id,
          name: listserv.name,
          next_digest_send_time: listserv.next_digest_send_time.try(:iso8601),
          digest_send_time: listserv.digest_send_time
        })
      end
    end

    context 'listserv does not exist' do
      it 'returns 404 (not found)' do
        get '/api/v3/listservs/090998'
        expect(response.status).to eql 404
      end
    end
  end
end
