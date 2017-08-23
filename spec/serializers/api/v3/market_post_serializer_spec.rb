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
  end
end
