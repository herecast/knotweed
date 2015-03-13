json.events [@event_instance] do |ei|
  attrs = [:id, :title, :sponsor, :cost,
           :featured, :links, :pubdate, :authors, :category, :parent_category, :source_name, :publication_id, :location, 
           :parent_uri, :venue, :category_reviewed, :has_active_promotion, :authoremail,
           :event_url, :sponsor_url, :subtitle, :contact_phone, :contact_email, :contact_url]
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
