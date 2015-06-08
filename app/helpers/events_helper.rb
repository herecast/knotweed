module EventsHelper

  def  cost_label(event_instance)
    if event_instance.cost.present? && event_instance.cost_type.present?
      "#{event_instance.cost_type} - #{event_instance.cost}"
    elsif event_instance.cost.present? && !event_instance.cost_type.present?
      "#{event_instance.cost}"
    elsif !event_instance.cost.present? && event_instance.cost_type.present?
      "#{event_instance.cost_type}"
    else
      nil
    end
  end

  def event_instance_display(event_instance)
    time_range = event_instance.start_date.strftime("%-l:%M %P")
    if event_instance.end_date.present?
      time_range += " - " + event_instance.end_date.strftime("%-l:%M %P")
    end

    subtitle = ''

    if event_instance.subtitle.present?
      subtitle = ' - ' + event_instance.subtitle
    end

    instance_string = event_instance.start_date.strftime("%b %-d, %Y") + '  ' + time_range + subtitle
    instance_string
  end

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

  # helper method to provide values for search fields
  # based on existing search or session-stored search
  def event_search_field_value(key)
    if params[:reset]
      nil
    elsif session[:events_search].present?
      session[:events_search][key]
    elsif params[:q].present?
      params[:q][key]
    else
      nil
    end
  end

  def contact_display(event)
    display_string = ''
    display_string += event.contact_phone + ', ' if event.contact_phone.present?
    display_string += event.contact_email + ', ' if event.contact_email.present?
    display_string += event.contact_url + ', ' if event.contact_url.present?
    display_string.chomp!(', ')
  end

end
