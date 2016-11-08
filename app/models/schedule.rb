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

class Schedule < ActiveRecord::Base
  has_many :event_instances, dependent: :destroy
  belongs_to :event
  attr_accessor :_remove

  after_save :update_event_instances

  validates_presence_of :event

  def self.create_single_occurrence_from_event_instance(ei)
    schedule = Schedule.new({subtitle_override: ei.subtitle_override,
                             presenter_name: ei.presenter_name,
                             description_override: ei.description_override})
    schedule.event = ei.event
    schedule.save! # persist so we can assign event instance to it so that update_event_instances
    # doesn't end up replacing the instance
    ei.update_attribute :schedule_id, schedule.id
    args = {}
    args[:end_time] = ei.end_date.to_time if ei.end_date.present?
    schedule.schedule = IceCube::Schedule.new(ei.start_date, args) do |s|
      s.add_recurrence_rule IceCube::SingleOccurrenceRule.new(ei.start_date)
    end
    schedule.save!
    schedule
  end

  def self.build_from_ux_for_event(hash, event_id=nil)
    # handles all incoming UX data for schedules, including when we are removing them.
    if hash['id'].present?
      model = Schedule.find hash['id']
      if hash['_remove']
        model._remove = true
        return model # skip all the other stuff since it's a waste of effort
      end
    else
      model = Schedule.new
    end
    model.subtitle_override = hash['subtitle']
    model.presenter_name = hash['presenter_name']
    model.description_override = hash['description']
    model.event_id = event_id

    starts_at = Time.zone.at(hash['starts_at'].to_time)
    if hash['ends_at'].present?
      ends_at = Time.zone.at(hash['ends_at'].to_time)
      # this is annoyingly complex because ends_at can come in with any sort of date.
      # Usually today's date. But we only care about the time...except if it's the next day,
      # we care that it's on the next day.
      if ends_at.hour >= starts_at.hour
        end_time = Time.zone.local(starts_at.year, starts_at.month, starts_at.day, ends_at.hour, ends_at.min, ends_at.sec)
      else
        # just in case these are changing
        next_day = starts_at + 1.day
        new_year = next_day.year
        new_month = next_day.month
        end_time = Time.zone.local(new_year, new_month, next_day.day, ends_at.hour, ends_at.min, ends_at.sec)
      end
      duration = end_time - starts_at
    end
    sched = IceCube::Schedule.new(starts_at, duration: duration)

    rule = Schedule.parse_repeat_info_to_rule(hash)
    unless rule.is_a? IceCube::SingleOccurrenceRule
      rule = rule.until(Time.zone.at(hash['end_date'].to_time.end_of_day))
    end

    sched.add_recurrence_rule rule

    # parse exception times
    # note, overrides can come in as a NIL thanks to rails parsing empty
    # JSON arrays as nil.
    if hash['overrides'].present?
      hash['overrides'].each do |i|
        if i['hidden'] # this data structure is to support instance specific data overrides in the future
          # exceptions are passed just as dates, so we need to assign them the start time 
          # for them to work consistently.
          exc = Time.zone.at(i['date'].to_time)
          exception_time = Time.zone.local(exc.year, exc.month, exc.day, starts_at.hour, starts_at.min, starts_at.sec)
          sched.add_exception_time exception_time
        end
      end
    end

    model.recurrence = sched.to_yaml
    model
  end

  def schedule
    IceCube::Schedule.from_yaml recurrence if recurrence.present?
  end

  def schedule=(sched)
    self.recurrence = sched.to_yaml
  end

  def to_icalendar_event
    tz = Time.zone.tzinfo.name
    event = Icalendar::Event.new
    my_schedule = schedule
    first_occurrence = my_schedule.all_occurrences.first
    event.dtstart = Icalendar::Values::DateTime.new(first_occurrence.start_time.to_datetime, tzid: tz)
    # ice-cube will automatically set the end_time to start_time if it's not supplied by the end user.
    # if end_time is not given, set end_time to start_time + 1 hour
    if first_occurrence.end_time.to_i == first_occurrence.start_time.to_i
      event.dtend = Icalendar::Values::DateTime.new(first_occurrence.start_time.to_datetime + 1.hour, tzid: tz)
    else
      event.dtend = Icalendar::Values::DateTime.new(first_occurrence.end_time.to_datetime, tzid: tz)
    end
    event.rrule = Icalendar::Values::Array.new([], Icalendar::Values::Recur) if my_schedule.recurrence_rules.present?
    my_schedule.recurrence_rules.each do |r|
      event.rrule << Icalendar::Values::Recur.new(r.to_ical)
    end
    event.rdate = Icalendar::Values::Array.new([], Icalendar::Values::DateTime) if my_schedule.send(:recurrence_times_without_start_time).present?
    my_schedule.send(:recurrence_times_without_start_time).each do |rt|
      event.rdate << Icalendar::Values::DateTime.new(rt.to_datetime, tzid: tz)
    end
    event.exdate = Icalendar::Values::Array.new([], Icalendar::Values::DateTime) if my_schedule.exception_times.present?
    my_schedule.exception_times.each do |ex|
      event.exdate << Icalendar::Values::DateTime.new(ex.to_datetime, tzid: tz) 
    end
    event.summary = subtitle_override.present? ? self.event.title + "\: #{subtitle_override}" : self.event.title
    sane_description = strip_tags(self.event.description).gsub('&nbsp;','')
    event.description = presenter_name.present? ? "PRESENTED BY\: #{presenter_name}\n\n" + sane_description : sane_description
    event.location = self.event.try(:venue).try(:name)
    if ConsumerApp.current.present?
      event.url = ConsumerApp.current.uri + "/events/#{self.event.event_instances.first.try(:id)}"
    end
    event
  end

  def set_schedule!(sched)
    self.schedule = sched
    self.save
  end

  # convenience methods that let us interact with IceCube schedule
  # directly on the schedule model
  def add_recurrence_rule!(rule)
    sched = schedule
    sched.add_recurrence_rule rule
    set_schedule!(sched)
  end

  def add_exception_time!(time)
    sched = schedule
    sched.add_exception_time time
    set_schedule!(sched)
  end

  # returns hash keyed by date integers for each event instance
  def event_instances_by_date
    hash = {}
    EventInstance.where(schedule_id: id).each do |ei| 
      hash[ei.start_date.to_i] = ei
    end
    hash
  end

  # create or update event_instances for schedule
  def update_event_instances
    if self.schedule.present?
      # remove no longer existent occurrences
      EventInstance.where(schedule_id: id).each do |ei|
        ei.destroy unless self.schedule.all_occurrences.map{ |o| o.start_time.to_i }.include? ei.start_date.to_i
      end
      eis_by_date = event_instances_by_date

      # add new occurrences
      schedule.each_occurrence do |occurrence|
        if !eis_by_date.has_key? occurrence.start_time.to_i
          attrs = {
            schedule_id: self.id, 
            event_id: event.id,
            start_date: occurrence.start_time,
            description_override: description_override,
            subtitle_override: subtitle_override,
            presenter_name: presenter_name
          }
          attrs[:end_date] = occurrence.end_time unless occurrence.start_time == occurrence.end_time
          EventInstance.create(attrs)
        else
          ei = eis_by_date[occurrence.start_time.to_i]
          # update end dates if need be -- unfortunately, since end_dates are all different
          # (even though duration is the same), these have to be updated by separate queries
          if ei.end_date.to_i != occurrence.end_time.to_i and 
            if occurrence.end_time == occurrence.start_time 
              # support removing end times from schedules/instances
              # if ei.end_date is already nil, we can skip the db call here
              ei.update_attribute :end_date, nil unless ei.end_date.nil?
            else
              ei.update_attribute :end_date, occurrence.end_time 
            end
          end
        end
      end
      # do this in a single batch rather than in the above 'else' clause so that we can
      # update all the event instances with a single query. If any of these fields change,
      # all the instances will need to be updated, so handle it here.
      update_hash = {}
      update_hash[:presenter_name] = presenter_name if presenter_name_changed?
      update_hash[:subtitle_override] = subtitle_override if subtitle_override_changed?
      update_hash[:description_override] = description_override if description_override_changed?
      # have to do this manually since update_all skips callbacks but we don't want to make more than
      # one sql query
      update_hash[:updated_at] = Time.zone.now
      event_instances.update_all(update_hash) unless update_hash.empty?
    end
    event_instances
  end

  def to_ux_format
    hash = {
      subtitle: subtitle_override,
      presenter_name: presenter_name,
      starts_at: schedule.start_time,
      id: id
    }
    hash[:ends_at] = schedule.start_time + schedule.duration if schedule.duration > 0
    # single recurrence rules work differently
    if schedule.recurrence_rules.present?
      # ice cube supports more than one rule per schedule, but our UX doesn't,
      # so just take the first rule
      rule = schedule.recurrence_rules.first
      hash[:end_date] = rule.until_time if rule.until_time.present?
      rule_hash = rule.to_hash
      if rule.is_a? IceCube::DailyRule
        repeats = 'daily'
      elsif rule.is_a? IceCube::WeeklyRule
        if rule_hash[:interval] == 2
          repeats = 'bi-weekly'
        else
          repeats = 'weekly'
        end
        days_of_week = rule_hash[:validations][:day].map{|d| d+1}
      elsif rule.is_a? IceCube::MonthlyRule
        repeats = 'monthly'
        # [:validations][:day_of_week] looks like this: { 3 => [1] }
        # in current implementation, we only ever have one day of week here.
        key_for_days_of_week = rule_hash[:validations][:day_of_week].keys.first
        weeks_of_month = rule_hash[:validations][:day_of_week][key_for_days_of_week].map{|w| w-1 }
        days_of_week = [key_for_days_of_week+1]
      end
    elsif schedule.recurrence_times.present?
      repeats = 'once' # while technically, an IceCube schedule can support multiple SingleOccurrenceRules,
      # our UX does not support including that in one schedule. So we don't need to worry about it here,
      # and the schedule already contains all the data we need.
      hash[:end_date] = schedule.start_time
    end
    hash[:repeats] = repeats
    hash[:days_of_week] = days_of_week
    hash[:weeks_of_month] = weeks_of_month

    if schedule.exception_times.present?
      hash[:overrides] = []
      schedule.exception_times.each do |et|
        hash[:overrides] << { date: et, hidden: true }
      end
    end
    hash
  end

  protected

  def self.parse_repeat_info_to_rule(hash)
    repeats = hash['repeats']
    if hash['days_of_week'].present?
      d_o_w = hash['days_of_week'].map{ |d| d-1 } # ember app and IceCube are off by 1 day in their treatment
      # of days of week
    end
    if repeats == 'daily'
      IceCube::Rule.daily
    elsif repeats == 'weekly'
      IceCube::Rule.weekly.day(d_o_w)
    elsif repeats == 'bi-weekly'
      IceCube::Rule.weekly(2).day(d_o_w)
    elsif repeats == 'monthly'
      # note -- as of now, we only support recurring on one day of week during one week of month.
      # This code could easily be modified to support more than that in the future by mapping
      # the days_of_week to arrays of weeks_of_month
      # Also, the UI has a 0 based week system while IceCube is 1-4
      IceCube::Rule.monthly.day_of_week(d_o_w[0] => [hash['weeks_of_month'][0]+1])
    elsif repeats == 'once'
      IceCube::SingleOccurrenceRule.new(Chronic.parse(hash['starts_at']))
    else
      false
    end
  end
end
