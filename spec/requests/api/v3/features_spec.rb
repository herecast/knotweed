require 'rails_helper'

RSpec.describe 'Feature API Endpoints', type: :request do
  describe 'GET /api/v3/features' do
    let!(:active_features) { FactoryGirl.create_list(:feature, 2, active: true) }
    let(:feature) { FactoryGirl.create :feature }

    it 'responsds 200' do
      get '/api/v3/features' do
        expect(response.status).to eq 200
      end
    end

    it 'returns active features' do
      get '/api/v3/features'
      expect(response_json[:features].count).to eq active_features.count

      response_json[:features].each do |feature|
        expect(feature).to match(a_hash_including({
          name: a_kind_of(String)
        }))
      end
    end
  end
end
