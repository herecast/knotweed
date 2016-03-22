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

  describe 'can_edit' do
    context 'Given context[:current_ability] able to manage' do
      it 'should be true' do
        ability = double('ability')
        expect(ability).to receive(:can?).with(:manage, @business_profile.content).and_return(true)

        serialized_object = JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false, context: {current_ability: ability}).to_json)
        expect(serialized_object['can_edit']).to be true
      end
    end
    context 'Given context[:current_ability] not able to manage' do
      it 'should be true' do
        ability = double('ability')
        expect(ability).to receive(:can?).with(:manage, @business_profile.content).and_return(false)

        serialized_object = JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false, context: {current_ability: ability}).to_json)
        expect(serialized_object['can_edit']).to be false
      end
    end
  end
end
