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
    instance_attrs = [:start_date]
  else
    # just make sure we don't include id here
    event_attrs = Event.truncated_event_fields - [:id]
    instance_attrs = [:id, :start_date, :subtitle, :description]

    json.partial! 'api/v1/business_locations/show', venue: e.event.venue if e.event.venue.present?

    if e.event.content.images.present?
      json.image e.event.content.images[0].image.url
    end
    json.content_id e.event.content.id
    # needed for constructing appropriate URLs on consumer side
    json.event_id e.event.id
  end

  instance_attrs.each { |attr| json.set! attr, e.send(attr) }
  event_attrs.each { |attr| json.set! attr, e.event.send(attr) }
end
