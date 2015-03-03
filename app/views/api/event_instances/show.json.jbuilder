json.events [@event_instance] do |ei|
  attrs = [:id, :title, :sponsor, :cost,
           :featured, :links, :pubdate, :authors, :category, :parent_category, :source_name, :source_id, :location, 
           :parent_uri, :venue, :category_reviewed, :has_active_promotion, :authoremail,
           :event_url, :sponsor_url, :subtitle]
  json.event_id ei.event.id
  json.content_id ei.event.content_id
  json.content ei.event.description

  if ei.event.images.present?
    json.image ei.event.images.first.image.url
  end

  attrs.each{|attr| json.set! attr, ei.event.send(attr) }
  json.event_instances @event_instance.event.event_instances
end
