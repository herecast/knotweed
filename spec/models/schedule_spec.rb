require 'spec_helper'

describe Schedule do
  describe 'after_create :create_event_instances' do
    before do
      @recurrence = IceCube::Schedule.new(Time.now) do |s|
        s.add_recurrence_rule IceCube::Rule.daily.until 1.week.from_now
      end
      @event = FactoryGirl.create :event # note, creates an event instance
    end

    subject { FactoryGirl.create :schedule, recurrence: @recurrence.to_yaml, event: @event }

    it 'should create the right number of event instances' do
      expect{subject}.to change{EventInstance.count}.by(@recurrence.all_occurrences.count)
    end

    it 'should associate the correct number of new event_instances with the event' do
      expect{subject}.to change{@event.event_instances.count}.by @recurrence.all_occurrences.count
    end

    it 'should associate the new event_instances with the schedule and the event' do
      subject
      sched = Schedule.last
      sched.event_instances.count.should eq(@recurrence.all_occurrences.count)
    end
  end

end
