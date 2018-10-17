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
#  presenter_name       :string(255)
#  schedule_id          :integer
#
# Indexes
#
#  idx_16625_index_event_instances_on_end_date    (end_date)
#  idx_16625_index_event_instances_on_event_id    (event_id)
#  idx_16625_index_event_instances_on_start_date  (start_date)
#

class EventInstance < ActiveRecord::Base
  include EmailTemplateHelper

  searchkick callbacks: :async,
    batch_size: 100,
    index_prefix: Figaro.env.searchkick_index_prefix,
    searchable: [:content, :title, :subtitle, :event_category, :venue_city, :venue_name]

  belongs_to :event
  delegate :created_by, :organization, :organization_id,
    to: :event

  belongs_to :schedule

  # it was requested to only have end time, not end date.
  # Rather than change the field, I've just turned it into a time picker
  # that needs to be combined with the date from start_date into a full date.
  before_save :process_end_time

  has_many :other_instances,
# cannot eager load if we include this
#    ->(instance) { where("id <> ?", instance.id) },
    class_name: 'EventInstance',
    foreign_key: 'event_id',
    primary_key: 'event_id'


  validates_presence_of :start_date
  validate :end_date_after_start_date

  scope :search_import, -> {
    includes(
      :other_instances,
      {
        event:  [
          {
            content: [
              :created_by,
              :organization,
              :location,
              {comments: :created_by},
              :images
            ]
          },
          :venue
        ]
      }
    ).joins(event: :content)\
      .where('contents.root_content_category_id > 0')
  }

  def search_data
    SearchIndexing::DetailedEventInstanceSerializer.new(self).serializable_hash
  end

  # takes the end_date and automatically sets it to the same date as start_date,
  # but with its own time
  def process_end_time
    if end_date.present?
      date_format = '%Y-%m-%d'
      time_format = "T%H:%M:%S%z"
      self.end_date = DateTime.strptime(
        start_date.strftime(date_format) + end_date.strftime(time_format),
        "#{date_format}#{time_format}"
      )
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

  def self.active_dates
    self.group('DATE(start_date)').count
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
      ev.url = url_for_consumer_app("/events/#{id}")
      ev
    end

end
