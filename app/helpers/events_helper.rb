module EventsHelper

  # convert start_date (and optional end_date) to a human readable time range
  #
  # @param [Event]
  # @return [String] of start date and time (or optionally range from startdatetime to enddatetime)
  def full_event_date_display(event)
    result = full_date_string(event.start_date)
    if event.end_date.present?
      result.sub!("at ", "")
      result += " to "
      # if they are on the same day, but different times, display just time
      if event.start_date.strftime("%A, %B %-d") == event.end_date.strftime("%A, %B %-d")
        result += event.end_date.strftime("%-l:%M %P")
      else
        result += full_date_string(event.end_date)
        result.sub!("at ", "")
      end
    end
    result
  end

  # converts a timestamp to a human readable string
  #
  # @param [timestamp]
  # @return [String] of form Monday, July 1 at 3:00 pm
  def full_date_string(date)
    date.strftime("%A, %B %-d at %-l:%M %P")
  end

end