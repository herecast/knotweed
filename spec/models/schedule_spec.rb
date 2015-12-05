require 'spec_helper'

describe Schedule do
  describe 'after_save :update_event_instances' do

    describe 'on creation' do
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

    describe 'on update' do
      before do
        @recurrence = IceCube::Schedule.new(Time.now) do |s|
          s.add_recurrence_rule IceCube::Rule.daily.until 2.weeks.from_now
        end
        @event = FactoryGirl.create :event
        @schedule = FactoryGirl.create :schedule, recurrence: @recurrence.to_yaml, event: @event
        @schedule.reload
      end

      subject do 
        @schedule.recurrence = IceCube::Schedule.new(Time.now) do |s|
          s.add_recurrence_rule IceCube::Rule.weekly.until 2.weeks.from_now
        end.to_yaml
        @schedule.save
      end

      it 'should change the number of event instances associated with the schedule' do
        expect{subject}.to change{@schedule.event_instances.count}.by -12
      end

      it 'should change the number of event instances associated with the event' do
        expect{subject}.to change{@event.event_instances.count}.by -12
      end

      it 'should change the number of event instances' do
        expect{subject}.to change{EventInstance.count}.by -12
      end
    end

    describe 'updating event instance attributes' do
      before do
        @recurrence = IceCube::Schedule.new(Time.now) do |s|
          s.add_recurrence_rule IceCube::Rule.daily.until 2.weeks.from_now
        end
        @event = FactoryGirl.create :event
        @schedule = FactoryGirl.create :schedule, recurrence: @recurrence.to_yaml, event: @event,
          description_override: 'zilch', presenter_name: 'blargh', subtitle_override: 'nom'
      end

      subject do
        @schedule.description_override = 'New override'
        @schedule.presenter_name = 'Test McTester'
        @schedule.subtitle_override = 'new subtitle'
        @schedule.save
      end

      it 'should update the associated event instance attributes' do
        subject
        @schedule.reload
        example_instance = @schedule.event_instances.first
        example_instance.presenter_name.should eq @schedule.presenter_name
        example_instance.subtitle_override.should eq @schedule.subtitle_override
        example_instance.description_override.should eq @schedule.description_override
      end
    end

  end

end
