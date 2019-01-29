# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::EventInstanceSerializer do
  before do
    @event = FactoryGirl.create :event
    @event_instance = FactoryGirl.create(:event_instance, event_id: @event.id)
  end

  let(:serialized_object) { JSON.parse(Api::V3::EventInstanceSerializer.new(@event_instance).to_json) }

  it 'should return a cost_type' do
    expect(serialized_object['event_instance']['cost_type']).to eq @event.cost_type
  end
end
