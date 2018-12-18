# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::BusinessProfileSerializer do
  before do
    @business_profile = FactoryGirl.create :business_profile
    @business_profile.business_location = FactoryGirl.create :business_location
  end

  let (:serialized_object) { JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false).to_json) }

  describe 'can_edit' do
    context 'Given context[:current_ability] able to manage' do
      it 'should be true' do
        ability = double('ability')
        expect(ability).to receive(:can?).with(:manage, @business_profile.content).and_return(true)

        serialized_object = JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false, context: { current_ability: ability }).to_json)
        expect(serialized_object['can_edit']).to be true
      end
    end
    context 'Given context[:current_ability] not able to manage' do
      it 'should be false' do
        ability = double('ability')
        expect(ability).to receive(:can?).with(:manage, @business_profile.content).and_return(false)

        serialized_object = JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false, context: { current_ability: ability }).to_json)
        expect(serialized_object['can_edit']).to be false
      end
    end
  end

  describe '#hours' do
    context 'when hours present' do
      it 'returns array of hours in schema.org format' do
        ability = double('ability')
        expect(ability).to receive(:can?).with(:manage, @business_profile.content).and_return(false)

        serialized_object = JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false, context: { current_ability: ability }).to_json)
        expect(serialized_object['hours']).to eq @business_profile.business_location.hours
      end
    end

    context 'when hours not present' do
      it 'returns an empty array' do
        ability = double('ability')
        expect(ability).to receive(:can?).with(:manage, @business_profile.content).and_return(false)

        @business_profile.business_location.update_attribute(:hours, nil)

        serialized_object = JSON.parse(Api::V3::BusinessProfileSerializer.new(@business_profile, root: false, context: { current_ability: ability }).to_json)
        expect(serialized_object['hours']).to eq []
      end
    end
  end
end
