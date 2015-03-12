json.events [@event_instance] do |ei|
  # while we are able to call content methods directly on events,
  # it's significantly better performance wise to call event.content.method
  # instead, so I'm separating this into content_attrs and event_attrs
  attrs = [:id, :sponsor, :cost, :featured, :links, 
           :venue, :event_url, :sponsor_url, :contact_phone, :contact_email, :contact_url]
  content_attrs = [:title, :pubdate, :authors, :category, :parent_category, :source_name, :source_id,
                  :parent_uri, :category_reviewed, :has_active_promotion, :authoremail,
                  :subtitle]
  json.event_id ei.event.id
  json.content_id ei.event.content.id
  json.content ei.event.content.raw_content

  if ei.event.content.images.present?
    json.image ei.event.content.images.first.image.url
  end

  attrs.each{|attr| json.set! attr, ei.event.send(attr) }
  content_attrs.each{|attr| json.set! attr, ei.event.content.send(attr) }
  json.event_instances @event_instance.event.event_instances
end
