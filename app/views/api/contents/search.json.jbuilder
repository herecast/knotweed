attrs = [:id, :title, :start_date, :end_date, :event_type, :host_organization, :cost, :recurrence,
         :featured, :links, :pubdate, :authors, :category, :source_name, :location, 
         :parent_uri]

json.page @page unless @page.nil?
json.total_pages @pages unless @pages.nil?
json.contents @contents do |c|
  json.content fix_ts_excerpt(c.excerpts.content)
  json.title fix_ts_excerpt(c.excerpts.title)
  json.score c.weight
  attrs.each{|attr| json.set! attr, c.send(attr) }
  if c.images.present?
    json.image c.images.first.image.url
  end
end
