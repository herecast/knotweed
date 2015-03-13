json.events [@event] do |e|
  attrs = [:id, :title, :start_date, :end_date, :sponsor, :cost,
           :featured, :links, :pubdate, :authors, :category, :parent_category, :source_name, :source_id, :location, 
           :parent_uri, :venue, :category_reviewed, :has_active_promotion, :authoremail,
           :event_url, :sponsor_url, :subtitle, :contact_phone, :contact_email, :contact_url]
  json.content e.sanitized_content

  # include the attached content record's id so that it can be used to retrieve related content
  json.content_id e.content.id

  if e.images.present?
    json.image e.images.first.image.url
  end
  attrs.each{|attr| json.set! attr, e.send(attr) }
end
