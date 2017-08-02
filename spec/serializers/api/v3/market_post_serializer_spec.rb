require 'spec_helper'

describe Api::V3::MarketPostSerializer do
  before do
    @market_post = FactoryGirl.create :market_post
  end

  let(:serialized_object) { JSON.parse(Api::V3::MarketPostSerializer.new(@market_post.content).to_json) }

  context 'fields' do
    it 'returns a cost field' do
      expect(serialized_object['market_post']['cost']).to eql @market_post.cost
    end

    it 'returns base_location_names' do
      location = FactoryGirl.create :location
      @market_post.content.base_locations=[location]

      expect(serialized_object['market_post']['base_location_names']).to eql [location.name]
    end
  end
end
