json.events [@event_instance] do |ei|
  attrs = [:title, :sponsor, :cost,
           :featured, :links, :pubdate, :authors, :category, :parent_category, :source_name, :source_id, :location, 
           :parent_uri, :venue, :category_reviewed, :has_active_promotion, :authoremail,
           :event_url, :sponsor_url, :subtitle]
  json.id ei.id
  json.event_id ei.event.id
  json.content_id ei.event.content_id
  json.content ei.event.description

  if ei.event.images.present?
    json.image ei.event.images.first.image.url
  end

  attrs.each{|attr| json.set! attr, ei.event.send(attr) }
  json.instances @event_instance.event.event_instances
end
