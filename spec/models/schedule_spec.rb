require 'spec_helper'

describe Schedule do
  describe 'after_save :update_event_instances' do

    describe 'on creation' do
      before do
        @recurrence = IceCube::Schedule.new(Time.zone.now) do |s|
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
        @recurrence = IceCube::Schedule.new(Time.zone.now) do |s|
          s.add_recurrence_rule IceCube::Rule.daily.until 2.weeks.from_now
        end
        @event = FactoryGirl.create :event
        @schedule = FactoryGirl.create :schedule, recurrence: @recurrence.to_yaml, event: @event
        @schedule.reload
      end

      subject do 
        @schedule.recurrence = IceCube::Schedule.new(Time.zone.now) do |s|
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
        @recurrence = IceCube::Schedule.new(Time.zone.now) do |s|
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
        @time = Time.zone.local(2015, 9, 1, 12, 0, 0)
        @schedule = FactoryGirl.create :schedule, recurrence: IceCube::Schedule.new(@time,
                  duration: @duration){ |s| s.add_recurrence_rule IceCube::Rule.daily.until(@time + 1.week)}.to_yaml
      end

      it 'should create event instances with the correct end_date based on duration parameter' do
       @schedule.event_instances.each do |ei|
         ei.end_date.should eq(ei.start_date + @duration)
       end
      end

      describe 'changing the duration' do
        before do
          @new_duration = @duration + 1.hour
          @new_recurrence = IceCube::Schedule.new(@time, duration: @new_duration) do |s|
            s.add_recurrence_rule IceCube::Rule.daily.until(@time+1.week)
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
          @schedule.recurrence = IceCube::Schedule.new(Time.zone.now, duration: @duration) do |s|
            s.add_recurrence_rule IceCube::Rule.daily.until 1.week.from_now
            s.add_exception_time(Time.zone.now + 2.days)
          end.to_yaml
          @schedule.save
        end

        it 'should remove an event_instance' do
          expect{subject}.to change{@schedule.reload.event_instances.count}.by -1
        end
      end
    end

    context 'with event instances with overlapping durations' do
      before do
        @schedule = FactoryGirl.create :schedule,
          recurrence: IceCube::Schedule.new(Chronic.parse("today at 2pm"),
            duration: 2.hours){ |s| s.add_recurrence_rule IceCube::Rule.hourly.until(Chronic.parse('tomorrow at 2pm')) }.to_yaml
      end

      it 'should start with the right number of event instances' do
        @schedule.reload.event_instances.count.should eq(25)
      end

      it 'should remove an event_instance if an exception is added' do
        @schedule.add_exception_time!(Chronic.parse('today at 4pm'))
        @schedule.reload.event_instances.count.should eq 24
      end
    end
  end

  describe 'add_recurrence_rule!(rule)' do 
    before do
      @schedule = FactoryGirl.create :schedule, recurrence: IceCube::Schedule.new().to_yaml
      @rule = IceCube::Rule.daily.until(1.week.from_now)
    end

    subject! { @schedule.add_recurrence_rule!(@rule) }

    it 'should add and persist an IceCube recurrence rule' do
      @schedule.reload.schedule.recurrence_rules.should include(@rule)
    end

    describe 'should trigger update_event_instances' do
      it 'should create event_instances for the schedule' do
        EventInstance.where(schedule_id: @schedule.id).count.should eq 7
      end
    end
  end

  describe 'add_exception_time!(time)' do
    before do
      @schedule = FactoryGirl.create :schedule
      @exception_time = @schedule.schedule.all_occurrences[3]
      @original_count = EventInstance.where(schedule_id: @schedule.id).count
    end

    subject! { @schedule.add_exception_time!(@exception_time) }

    it 'should add and persist an IceCube exception time' do
      @schedule.schedule.exception_times.should include(@exception_time)
    end

    it 'should remove the excepted event instance' do
      EventInstance.where(schedule_id: @schedule.id).map{ |ei| ei.start_date.to_i}.should_not include(@exception_time.to_i)
      EventInstance.where(schedule_id: @schedule.id).count.should eq(@original_count - 1)
    end
  end

  describe 'Schedule.build_from_ux_for_event' do
    before do
      f = File.new('spec/fixtures/schedule_input_1.json', 'r')
      # the method takes a single schedule input, but the Ember app passes us 
      # an event record with an array of schedules. This particular test case
      # has just one schedule in it.
      @input = JSON.parse(f.read)['event']['schedules'][0]
      @event = FactoryGirl.create :event
      @schedule = Schedule.build_from_ux_for_event(@input, @event.id) 
    end

    it 'should be valid' do
      @schedule.should be_valid
    end

    it 'should have the expected start_time' do
      @schedule.schedule.start_time.should eq Chronic.parse('2015-12-01T14:00:00.000Z')
    end

    it 'should have the expected recurrence rules' do
      rule = IceCube::Rule.weekly.day(2,5).until(Chronic.parse('2015-12-31T15:00:00.000Z'))
      @schedule.schedule.recurrence_rules.should eq [rule]
    end

    it 'should have the expected exception times' do
      times = [Chronic.parse('2015-12-14T14:00:00.000Z'), Chronic.parse('2015-12-28T14:00:00.000Z')]
      @schedule.schedule.exception_times.should eq times
    end

  end

  describe 'to_ux_format' do
    before do
      @schedule = FactoryGirl.build :schedule, recurrence: nil
      @basic_response = {
        subtitle: @schedule.subtitle_override,
        presenter_name: @schedule.presenter_name,
        starts_at: @start_time=Time.local(2015),
        ends_at: @end_time=Time.local(2015)+2.months
      }
    end

    let(:output) { @schedule.to_ux_format }

    rules_and_outputs = {
      'daily' => {
        rule: IceCube::Rule.daily,
        repeats_fields: { repeats: 'daily', days_of_week: nil, weeks_of_month: nil }
      },
      'weekly' => {
        rule: IceCube::Rule.weekly.day(3),
        repeats_fields: { repeats: 'weekly', days_of_week: [4], weeks_of_month: nil }
      },
      'bi-weekly' => {
        rule: IceCube::Rule.weekly(2).day(5),
        repeats_fields: { repeats: 'bi-weekly', days_of_week: [6], weeks_of_month: nil }
      },
      'monthly' => {
        rule: IceCube::Rule.monthly.day_of_week(3 => [2]),
        repeats_fields: { repeats: 'monthly', days_of_week: [4], weeks_of_month: [1] }
      },
      'once' => {
        rule: IceCube::SingleOccurrenceRule.new(Time.local(2015)),
        repeats_fields: { repeats: 'once', days_of_week: nil, weeks_of_month: nil }
      }
    }

    rules_and_outputs.each do |type, specifics|
      it "should generate the correct hash response for a #{type} recurrence" do
        @schedule.schedule = IceCube::Schedule.new(@start_time, end_time: @end_time){ |s| s.add_recurrence_rule specifics[:rule] }
        output.should eq(specifics[:repeats_fields].merge(@basic_response))
      end
    end

    describe 'with exceptions' do
      before do
        @schedule.schedule = IceCube::Schedule.new(@start_time, end_time: @end_time) do |s|
          s.add_recurrence_rule IceCube::Rule.daily.until(@end_time)
          s.add_exception_time @start_time + 3.days
          s.add_exception_time @start_time + 5.days
        end
      end

      it 'should include the appropriate array of overrides' do
        output[:overrides].should be_present
        output[:overrides].count.should eq 2
        output[:overrides].each do |o|
          o[:hidden].should be_true
        end
      end
    end

  end
end
