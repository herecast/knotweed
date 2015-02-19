class EventInstance < ActiveRecord::Base
  belongs_to :event
  attr_accessible :description_override, :end_date, :event_id, :start_date, :subtitle_override

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
