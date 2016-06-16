# == Schema Information
#
# Table name: schedules
#
#  id                   :integer          not null, primary key
#  recurrence           :text
#  event_id             :integer
#  description_override :text
#  subtitle_override    :string(255)
#  presenter_name       :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

require 'spec_helper'

describe Schedule, :type => :model do
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
        expect(sched.event_instances.count).to eq(@recurrence.all_occurrences.count)
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
        expect(example_instance.presenter_name).to eq @schedule.presenter_name
        expect(example_instance.subtitle_override).to eq @schedule.subtitle_override
        expect(example_instance.description_override).to eq @schedule.description_override
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
         expect(ei.end_date).to eq(ei.start_date + @duration)
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
            expect(ei.end_date).to eq (ei.start_date + @new_duration)
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
        expect(@schedule.reload.event_instances.count).to eq(25)
      end

      it 'should remove an event_instance if an exception is added' do
        @schedule.add_exception_time!(Chronic.parse('today at 4pm'))
        expect(@schedule.reload.event_instances.count).to eq 24
      end
    end
  end

  describe 'add_recurrence_rule!(rule)' do
    before do
      @schedule = FactoryGirl.create :schedule, recurrence: IceCube::Schedule.new(Time.local(2015)).to_yaml
      @rule = IceCube::Rule.daily.until(Time.local(2015) + 1.week)
    end

    subject! { @schedule.add_recurrence_rule!(@rule) }

    it 'should add and persist an IceCube recurrence rule' do
      expect(@schedule.schedule.recurrence_rules).to include(@rule)
    end

    describe 'should trigger update_event_instances' do
      it 'should create event_instances for the schedule' do
        expect(EventInstance.where(schedule_id: @schedule.id).count).to eq 8
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
      expect(@schedule.schedule.exception_times).to include(@exception_time)
    end

    it 'should remove the excepted event instance' do
      expect(EventInstance.where(schedule_id: @schedule.id).map{ |ei| ei.start_date.to_i}).not_to include(@exception_time.to_i)
      expect(EventInstance.where(schedule_id: @schedule.id).count).to eq(@original_count - 1)
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
      expect(@schedule).to be_valid
    end

    it 'should have the expected start_time' do
      expect(@schedule.schedule.start_time).to eq Chronic.parse('2015-12-01T14:00:00.000Z')
    end

    it 'should have the expected end_time' do
      # we take the time passed as "ends_at" and use that to calculate a duration
      # with (ends_at - starts_at).abs, then create the schedule with that duration.
      # which should set the end_time to duration > start_time
      expect(@schedule.schedule.end_time).to eq @schedule.schedule.start_time + 1.hour
    end

    it 'should have the expected recurrence rules' do
      # if you just pass the UTC time in, the rule is different because of the way IceCube handles timezone info
      rule = IceCube::Rule.weekly.day(1,4).until(Time.zone.at('2015-12-31T15:00:00.000Z'.to_time.end_of_day))
      expect(@schedule.schedule.recurrence_rules).to eq [rule]
    end

    it 'should have the expected exception times' do
      times = [Chronic.parse('2015-12-14T14:00:00.000Z'), Chronic.parse('2015-12-28T14:00:00.000Z')]
      expect(@schedule.schedule.exception_times).to eq times
    end

    context 'when passed _remove for an existing schedule' do
      before do
        @schedule = FactoryGirl.create :schedule, event: @event
        @remove_input = @input.merge({'_remove' => true, 'id' => @schedule.id})
      end

      subject { Schedule.build_from_ux_for_event(@remove_input, @event.id) }

      it 'should set the _remove transient attribute to true' do
        expect(subject._remove).to be_truthy
      end
    end

    context 'when ends_at < starts_at' do
      before do
        @schedule = FactoryGirl.create :schedule, event: @event
        @weird_timing = @input.merge({ 'starts_at' => Time.now, "ends_at" => Time.now - 61 * 60 })
      end

      subject { Schedule.build_from_ux_for_event(@weird_timing, @event.id) }

      it 'should set the end date one day ahead' do
        timing = YAML.load(subject.recurrence)
        start = timing[:start_time][:time]
        finish = timing[:end_time][:time]
        expect(finish).to be > start
      end
    end

  end

  describe 'to_ux_format' do
    before do
      @schedule = FactoryGirl.build :schedule, recurrence: nil
      @basic_response = {
        subtitle: @schedule.subtitle_override,
        presenter_name: @schedule.presenter_name,
        starts_at: @start_time=Time.local(2015),
        ends_at: @end_time=Time.local(2015)+2.months,
        id: nil
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
        repeats_fields: { repeats: 'once', days_of_week: nil, weeks_of_month: nil, end_date: Time.local(2015)  }
      }
    }

    rules_and_outputs.each do |type, specifics|
      it "should generate the correct hash response for a #{type} recurrence" do
        @schedule.schedule = IceCube::Schedule.new(@start_time, end_time: @end_time){ |s| s.add_recurrence_rule specifics[:rule] }
        expect(output).to eq(specifics[:repeats_fields].merge(@basic_response))
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
        expect(output[:overrides]).to be_present
        expect(output[:overrides].count).to eq 2
        output[:overrides].each do |o|
          expect(o[:hidden]).to be_truthy
        end
      end
    end

  end

  describe 'Schedule.create_single_occurrence_from_event_instance(ei)' do
    before do
      @event = FactoryGirl.create :event, skip_event_instance: true
      @ei = FactoryGirl.create :event_instance, event: @event
      @schedule = Schedule.create_single_occurrence_from_event_instance(@ei)
    end

    it 'should create a new schedule associated with the same event' do
      expect(@event.schedules).to eq([@schedule])
    end

    it 'should correctly define the single occurrence of the schedule' do
      expect(@schedule.schedule.all_occurrences).to eq [@ei.start_date]
    end

    it 'should correctly associate the event instance with the new schedule' do
      expect(@schedule.event_instances).to eq [@ei]
      expect(@ei.schedule).to eq @schedule
      expect(EventInstance.where(event_id: @event.id)).to eq [@ei]
    end
  end

  describe 'schedule converted to ics' do
    context 'with text overrides' do
      before do
        @subtitle_override = Faker::Lorem.sentence(2,true,2)
        @schedule = FactoryGirl.create :schedule, subtitle_override: @subtitle_override
        @schedule.add_exception_time! @schedule.schedule.all_occurrences[1]
        @schedule.add_recurrence_rule! IceCube::SingleOccurrenceRule.new(Time.now)
        @ics = @schedule.to_icalendar_event.to_ical
      end

      it 'should have the expected fields' do
        expect(@ics).to match /VEVENT/
        expect(@ics).to match /DTSTART/
        expect(@ics).to match /DTEND/
        expect(@ics).to match "SUMMARY:#{@schedule.event.title}: #{@subtitle_override}"
        expect(@ics).to match /RRULE/
        expect(@ics).to match /RDATE/
        expect(@ics).to match /EXDATE/
      end
    end

    context 'without text override, with location' do
      before do
        @venue = FactoryGirl.create :business_location, name: Faker::Lorem.words(2).join(' ')
        event = FactoryGirl.create :event, venue: @venue
        @schedule = FactoryGirl.create :schedule, event: event
        @ics = @schedule.to_icalendar_event.to_ical
      end

      it 'should have the expected fields' do
        expect(@ics).to match /VEVENT/
        expect(@ics).to match /DTSTART/
        expect(@ics).to match /DTEND/
        expect(@ics).to match "DESCRIPTION:#{@schedule.event.description}"
        expect(@ics).to match /RRULE/
        expect(@ics).to match "LOCATION:#{@venue.name}"
      end
    end
  end
end
