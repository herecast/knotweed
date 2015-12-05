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

  def schedule=(sched)
    update_attribute :recurrence, sched.to_yaml
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
      schedule.each_occurrence do |date|
        unless eis_by_date.has_key? date
          EventInstance.create(
            schedule_id: self.id, 
            event_id: event.id,
            start_date: date,
            description_override: description_override,
            subtitle_override: subtitle_override,
            presenter_name: presenter_name
          )
        end
      end
      if description_override_changed? or subtitle_override_changed? or presenter_name_changed?
        event_instances.update_all({
          presenter_name: presenter_name,
          subtitle_override: subtitle_override,
          description_override: description_override
        })
      end
    end
    event_instances
  end
end
