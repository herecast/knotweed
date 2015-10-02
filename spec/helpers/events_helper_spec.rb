require 'spec_helper' 

describe EventsHelper, type: :helper do
  describe '#ux2_event_path' do
    before do
      @event = FactoryGirl.create :event
    end

    it 'should return /events/#{event_instance_id}' do
      expect(helper.ux2_event_path(@event)).to eq("/events/#{@event.event_instances.first.id}")
    end
  end
end
