json.events [@event] do |e|
  attrs = [:id, :title, :start_date, :end_date, :event_type, :host_organization, :cost, :recurrence,
           :featured, :links, :pubdate, :authors, :category, :parent_category, :source_name, :source_id, :location, 
           :parent_uri, :venue, :category_reviewed, :has_active_promotion, :authoremail,
           :event_url, :sponsor_url, :subtitle]
  json.content e.sanitized_content

  if e.images.present?
    json.image e.images.first.image.url
  end
  attrs.each{|attr| json.set! attr, e.send(attr) }
end
