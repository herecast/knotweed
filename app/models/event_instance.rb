class EventInstance < ActiveRecord::Base
  belongs_to :event
  attr_accessible :description_override, :end_date, :event_id, :start_date, :subtitle_override

  # it was requested to only have end time, not end date.
  # Rather than change the field, I've just turned it into a time picker
  # that needs to be combined with the date from start_date into a full date.
  before_save :process_end_time

  validates_presence_of :start_date

  # takes the end_date and automatically sets it to the same date as start_date,
  # but with its own time
  def process_end_time
    if end_date.present?
      self.end_date = Chronic.parse(start_date.to_date.to_s + " " + end_date.strftime("%I:%M%p"))
    end
  end

  # returns instance's subtitle override if available,
  # otherwise returns event.subtitle
  def subtitle
    if subtitle_override.present?
      subtitle_override
    else
      event.subtitle
    end
  end

  def description
    if description_override.present?
      description_override
    else
      event.description
    end
  end

end
