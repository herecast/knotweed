# this is somewhat tricky. Our @event_instances instance variable is just event_instances
# In order to maintain a separate id for every event (so we can have different URLs on the content app),
# we're rendering events as a combination of event instances and events here and the consumer app
# doesn't know anything about it. 
json.events @event_instances do |e|
  # for each event instance, we render the full corresponding event record with the start date, id,
  # end date, and any override fields (right now, description and/or subtitle)
  # being provided by the instance model.
  event_attrs = []
  if params[:start_date_only] # calendar query
    instance_attrs = [:id, :start_date, :subtitle_override]
  else
    # just make sure we don't include id here
    event_attrs = Event.truncated_event_fields - [:id]
    instance_attrs = [:id, :start_date, :subtitle_override, :description]

    if e.event.images.present?
      json.image e.event.images.first.image.url
    end
  end

  instance_attrs.each { |attr| json.set! attr, e.send(attr) }
  event_attrs.each { |attr| json.set! attr, e.event.send(attr) }
end
