# frozen_string_literal: true

module EventsHelper
  def  cost_label(event_instance)
    if event_instance.cost.present? && event_instance.cost_type.present?
      "#{event_instance.cost_type} - #{event_instance.cost}"
    elsif event_instance.cost.present? && !event_instance.cost_type.present?
      event_instance.cost.to_s
    elsif !event_instance.cost.present? && event_instance.cost_type.present?
      event_instance.cost_type.to_s
    end
  end

  def event_instance_display(event_instance)
    time_range = event_instance.start_date.strftime('%-l:%M %P')
    if event_instance.end_date.present?
      time_range += ' - ' + event_instance.end_date.strftime('%-l:%M %P')
    end

    subtitle = ''

    if event_instance.subtitle.present?
      subtitle = ' - ' + event_instance.subtitle
    end

    instance_string = event_instance.start_date.strftime('%b %-d, %Y') + '  ' + time_range + subtitle
    instance_string
  end

  def friendly_schedule_date(schedule)
    subtitle = ''
    if schedule.subtitle_override.present?
      subtitle = ' - ' + schedule.subtitle_override
    end
    schedule = schedule.schedule
    return '', '' unless schedule.next_occurrence.present?

    event_date = schedule.next_occurrence.strftime('%b %-d, %Y')
    time_range = schedule.start_time.strftime('%-l:%M %P')
    time_range += ' - ' + schedule.end_time.strftime('%-l:%M %P') if schedule.end_time.present?
    [event_date.to_s + '  ' + time_range + subtitle, 'Repeats ' + schedule.to_s]
  end

  # converts a timestamp to a human readable string
  #
  # @param [timestamp]
  # @return [String] of form Monday, July 1 at 3:00 pm
  def full_date_string(date)
    date.strftime('%A, %B %-d at %-l:%M %P')
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
    end
  end

  def contact_display(event)
    display_string = ''
    display_string += event.contact_phone + ', ' if event.contact_phone.present?
    display_string += event.contact_email + ', ' if event.contact_email.present?
    display_string += event.event_url + ', ' if event.event_url.present?
    display_string.chomp!(', ')
  end
end
