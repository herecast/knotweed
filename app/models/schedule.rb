class Schedule < ActiveRecord::Base
  has_many :event_instances, dependent: :destroy
  belongs_to :event
  attr_accessible :recurrence, :description_override, :subtitle_override, :presenter_name

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
    if hash['id'].present?
      model = Schedule.find hash['id']
    else
      model = Schedule.new
    end
    model.subtitle_override = hash['subtitle']
    model.presenter_name = hash['presenter_name']
    model.description_override = hash['description']
    model.event_id = event_id

    ends_at = Chronic.parse(hash['ends_at'])
    sched = IceCube::Schedule.new(Chronic.parse(hash['starts_at']), end_time: ends_at.to_time)

    rule = Schedule.parse_repeat_info_to_rule(hash)
    unless rule.is_a? IceCube::SingleOccurrenceRule
      rule = rule.until(Chronic.parse(hash['ends_at']))
    end

    sched.add_recurrence_rule rule

    # parse exception times
    # note, overrides can come in as a NIL thanks to rails parsing empty
    # JSON arrays as nil.
    if hash['overrides'].present?
      hash['overrides'].each do |i|
        if i['hidden'] # this data structure is to support instance specific data overrides in the future
          sched.add_exception_time Chronic.parse(i['date'])
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
          EventInstance.create(
            schedule_id: self.id, 
            event_id: event.id,
            start_date: occurrence.start_time,
            end_date: occurrence.end_time,
            description_override: description_override,
            subtitle_override: subtitle_override,
            presenter_name: presenter_name
          )
        else
          ei = eis_by_date[occurrence.start_time.to_i]
          # update end dates if need be -- unfortunately, since end_dates are all different
          # (even though duration is the same), these have to be updated by separate queries
          if ei.end_date != occurrence.end_time
            ei.update_attribute :end_date, occurrence.end_time 
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
      event_instances.update_all(update_hash) unless update_hash.empty?
    end
    event_instances
  end

  def to_ux_format
    hash = {
      subtitle: subtitle_override,
      presenter_name: presenter_name,
      starts_at: schedule.start_time,
      ends_at: schedule.end_time,
      id: id
    }
    # single recurrence rules work differently
    if schedule.recurrence_rules.present?
      # ice cube supports more than one rule per schedule, but our UX doesn't,
      # so just take the first rule
      rule = schedule.recurrence_rules.first
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
