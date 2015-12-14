# == Schema Information
#
# Table name: event_instances
#
#  id                   :integer          not null, primary key
#  event_id             :integer
#  start_date           :datetime
#  end_date             :datetime
#  subtitle_override    :string(255)
#  description_override :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

class EventInstance < ActiveRecord::Base
  belongs_to :event
  belongs_to :schedule
  attr_accessible :description_override, :end_date, :event_id, :start_date, :subtitle_override,
    :presenter_name, :schedule_id

  # it was requested to only have end time, not end date.
  # Rather than change the field, I've just turned it into a time picker
  # that needs to be combined with the date from start_date into a full date.
  before_save :process_end_time

  validates_presence_of :start_date
  validate :end_date_after_start_date

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

  # validation method that confirms end_date is either nil
  # or greater than start_date.
  def end_date_after_start_date
    if end_date.present? and end_date < start_date
      errors.add(:end_time, "End date cannot be before start date.")
    end
  end

  # returns ics format of this event
  def to_ics
    cal = Icalendar::Calendar.new
    cal.add_event ics_event_attributes
    cal.to_ical
  end

  private
    
    # private because this is a helper method for to_ics
    # may be called with send if needed
    def ics_event_attributes
      ev = Icalendar::Event.new
      ev.dtstart = start_date
      ev.dtend = end_date
      ev.summary = self.event.title
      ev.description = strip_tags(description).gsub('&nbsp;','')
      ev.location = self.event.try(:venue).try(:name)
      if ConsumerApp.current.present?
        ev.url = ConsumerApp.current.uri + "/events/#{id}"
      end
      ev
    end

end
