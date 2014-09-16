json.page @page unless @page.nil?
json.total_pages @pages unless @pages.nil?
json.contents @contents do |c|
  [:id, :title, :start_date, :end_date, :event_type, :host_organization,
   :cost, :recurrence, :featured, :links, :pubdate, :authors, 
   :category, :source_name, :location, :parent_uri].each {|attr| json.set! attr, c.send(attr) }
  if c.images.present?
    json.image c.images.first.image.url
  end
end
