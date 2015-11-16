class Schedule < ActiveRecord::Base
  has_many :event_instances, dependent: :destroy
  belongs_to :event
  attr_accessible :recurrence, :description_override, :subtitle_override, :presenter_name

  after_create :create_event_instances

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

  # create event_instances for schedule
  def create_event_instances
    if schedule.present?
      schedule.each_occurrence do |date|
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
    event_instances
  end
end
