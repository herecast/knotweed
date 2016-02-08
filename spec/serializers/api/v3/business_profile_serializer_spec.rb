require 'spec_helper'

describe Api::V3::BusinessProfileSerializer do
  before do
    @business_profile = FactoryGirl.create :business_profile
  end

  let (:serialized_object) { JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false).to_json) }

  describe 'id' do
    it 'should be the associated content ID' do
      expect(serialized_object['id']).to eq @business_profile.content.id
    end
  end
end
