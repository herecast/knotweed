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

    context 'with event instance duration' do
      before do
        @duration = 30.minutes
        recurrence = IceCube::Schedule.new(Time.now, duration: @duration) do |s|
          s.add_recurrence_rule IceCube::Rule.daily.until 1.week.from_now
        end
        @schedule = FactoryGirl.create :schedule, recurrence: recurrence.to_yaml
      end

      it 'should create event instances with the correct end_date based on duration parameter' do
       @schedule.event_instances.each do |ei|
         ei.end_date.should eq(ei.start_date + @duration)
       end
      end

      describe 'changing the duration' do
        before do
          @new_duration = @duration + 1.hour
          @new_recurrence = IceCube::Schedule.new(Time.now, duration: @new_duration) do |s|
            s.add_recurrence_rule IceCube::Rule.daily.until 1.week.from_now
          end
        end

        subject { @schedule.update_attribute :recurrence, @new_recurrence.to_yaml }

        it 'should update the end_date of all associated event instances' do
          subject
          @schedule.event_instances.each do |ei|
            ei.end_date.should eq (ei.start_date + @new_duration)
          end
        end
      end

      describe 'adding an exception' do
        subject do
          @schedule.recurrence = IceCube::Schedule.new(Time.now, duration: @duration) do |s|
            s.add_recurrence_rule IceCube::Rule.daily.until 1.week.from_now
            s.add_exception_time(Time.now + 2.days)
          end.to_yaml
          @schedule.save
        end

        it 'should remove an event_instance' do
          expect{subject}.to change{@schedule.reload.event_instances.count}.by -1
        end
      end
    end
  end

  context 'with event instances with overlapping durations' do
    before do
      @schedule = FactoryGirl.create :schedule,
        recurrence: IceCube::Schedule.new(Time.now, duration: 2.hours){ |s| s.add_recurrence_rule IceCube::Rule.hourly.until 2.days.from_now }.to_yaml
    end

    subject { @schedule.reload.event_instances.count }
    

    it 'should start with the right number of event instances' do
     subject.should eq(49)
    end

    it 'should remove an event_instance when an exception is added' do
      expect{@schedule.add_exception_time!(3.hours.from_now)}.to change{subject}.by -1
    end
  end

  describe 'add_recurrence_rule!(rule)' do 
    before do
      @schedule = FactoryGirl.create :schedule
      @rule = IceCube::Rule.daily.until(1.week.from_now)
    end

    subject { @schedule.add_recurrence_rule!(@rule) }

    it 'should add and persist an IceCube recurrence rule' do
      expect{subject}.to change{@schedule.schedule.recurrence_rules}.to include(@rule)
    end
  end

  describe 'add_exception_time!(time)' do
    before do
      @schedule = FactoryGirl.create :schedule
      @exception_time = 2.hours.from_now
    end

    subject { @schedule.add_exception_time!(@exception_time) }

    it 'should add and persist an IceCube exception time' do
      expect{subject}.to change{@schedule.schedule.exception_times}.to include(@exception_time)
    end
  end

end
