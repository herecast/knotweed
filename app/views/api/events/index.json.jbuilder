json.events @events do |e|
  if params[:start_date_only] # calendar query
    attrs = Event.start_date_only_fields
  else
    attrs = Event.truncated_event_fields
    # populate the content attribute with raw_content for speed
    json.content e.raw_content

    if e.images.present?
      json.image e.images.first.image.url
    end
  end

  attrs.each { |attr| json.set! attr, e.send(attr) }
end
