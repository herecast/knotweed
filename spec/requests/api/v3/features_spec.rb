require 'rails_helper'

RSpec.describe 'Feature API Endpoints', type: :request do
  describe 'GET /api/v3/features' do
    let!(:active_features) { FactoryGirl.create_list(:feature, 2, active: true) }
    let!(:feature) { FactoryGirl.create :feature }

    it 'responsds 200' do
      get '/api/v3/features'
      expect(response.status).to eq 200
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

    context 'when options field is set' do
      before { Feature.destroy_all }
      let!(:nested_options_feature) { FactoryGirl.create :feature, active: true, options: '{"foo": "bar", "boo": {"baz": "buzz"}}' }

      it 'retuns and options boject if present' do
        get '/api/v3/features'
        expect(response_json[:features].first[:options]).to eq ({ foo: "bar", boo: { baz: "buzz" } })
      end
    end
  end
end
