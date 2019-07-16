# frozen_string_literal: true

class ReindexEventsWithFutureInstances < ApplicationJob
  def perform
    events = Content.includes(channel: :event_instances)
                    .where(channel_type: 'Event')
                    .where(has_future_event_instance: [true, nil])

    events.find_each do |e|
      start_date = e.channel.next_or_first_instance.try(:start_date)
      if start_date.present? && start_date >= Time.current
        e.reindex(mode: :async)
      else
        e.update_attribute(:has_future_event_instance, false)
      end
    rescue StandardError
    end
  end
end
