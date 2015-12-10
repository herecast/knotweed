class Schedule < ActiveRecord::Base
  has_many :event_instances, dependent: :destroy
  belongs_to :event
  attr_accessible :recurrence, :description_override, :subtitle_override, :presenter_name

  after_save :update_event_instances

  validates_presence_of :event

  def self.build_from_ux_for_event(hash, event_id=nil)
    if hash['id'].present?
      debugger
      model = Schedule.find hash['id']
    else
      model = Schedule.new
    end
    model.subtitle_override = hash['subtitle'],
    model.presenter_name = hash['presenter_name'],
    model.description_override = hash['description']
    model.event_id = event_id

    sched = IceCube::Schedule.new(Chronic.parse(hash['starts_at']))
    rule = Schedule.parse_repeat_info_to_rule(hash).until(Chronic.parse(hash['ends_at']))

    sched.add_recurrence_rule rule

    # parse exception times
    hash['overrides'].each do |i|
      if i['hidden'] # this data structure is to support instance specific data overrides in the future
        sched.add_exception_time Chronic.parse(i['date'])
      end
    end

    model.recurrence = sched.to_yaml
    model
  end

  def schedule
    if recurrence.present?
      IceCube::Schedule.from_yaml recurrence
    else
      nil
    end
  end

  def set_schedule!(sched)
    self.recurrence = sched.to_yaml
    self.save
  end

  # convenience methods that let us interact with IceCube schedule
  # directly on the schedule model
  def add_recurrence_rule!(rule)
    if schedule.present?
      sched = schedule
      sched.add_recurrence_rule rule
    else # default to creating a new schedule starting now
      sched = IceCube::Schedule.new(Time.now)
      sched.add_recurrence_rule rule
    end
    set_schedule!(sched)
  end

  def add_exception_time!(time)
    if schedule.present?
      sched = schedule
      sched.add_exception_time time
      set_schedule!(sched)
    else # doesn't make sense to add exception time when you don't have a schedule yet
      false
    end
  end

  # returns hash keyed by date integers for each event instance
  def event_instances_by_date
    hash = {}
    EventInstance.where(schedule_id: id).each do |ei| 
      hash[ei.start_date] = ei
    end
    hash
  end

  # create or update event_instances for schedule
  def update_event_instances
    if self.schedule.present?
      # remove no longer existent occurrences
      EventInstance.where(schedule_id: id).each do |ei|
        ei.destroy unless self.schedule.all_occurrences.include? ei.start_date
      end
      eis_by_date = event_instances_by_date

      # add new occurrences
      schedule.each_occurrence do |occurrence|
        if !eis_by_date.has_key? occurrence.start_time
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
          ei = eis_by_date[occurrence.start_time]
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

  protected

  def self.parse_repeat_info_to_rule(hash)
    repeats = hash['repeats']
    if repeats == 'daily'
      IceCube::Rule.daily
    elsif repeats == 'weekly'
      IceCube::Rule.weekly.day(hash['days_of_week'])
    elsif repeats == 'bi-weekly'
      IceCube::Rule.weekly(2).day(hash['days_of_week'])
    elsif repeats == 'monthly'
      IceCube::Rule.monthly
    else
      false
    end
  end
end
