class Schedule < ActiveRecord::Base
  has_many :event_instances, dependent: :destroy
  belongs_to :event
  attr_accessible :recurrence, :description_override, :subtitle_override, :presenter_name

  after_save :update_event_instances

  def schedule
    if recurrence.present?
      IceCube::Schedule.from_yaml recurrence
    else
      nil
    end
  end

  def set_schedule!(sched)
    update_attribute :recurrence, sched.to_yaml
  end

  # convenience methods that let us interact with IceCube schedule
  # directly on the schedule model
  def add_recurrence_rule!(rule)
    if schedule.present?
      sched = schedule
      sched.add_recurrence_rule rule
      set_schedule!(sched)
    else
      false
    end
  end

  def add_exception_time!(time)
    if schedule.present?
      sched = schedule
      sched.add_exception_time time
      set_schedule!(sched)
    else
      false
    end
  end

  # returns hash keyed by date objects for each event instance
  def event_instances_by_date
    hash = {}
    event_instances.each do |ei| 
      hash[ei.start_date] = ei
    end
    hash
  end

  # create or update event_instances for schedule
  def update_event_instances
    if schedule.present?
      # remove no longer existent occurrences
      event_instances.each do |ei|
        ei.destroy unless schedule.all_occurrences.include? ei.start_date
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
          ei = eis_by_date[occurrence]
          # update end dates if need be -- unfortunately, since end_dates are all different
          # (even though duration is the same), these have to be updated by separate queries
          ei.update_attribute :end_date, occurrence.end_time if ei.end_date != occurrence.end_time
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
end
