json.page @page unless @page.nil?
json.total_pages @pages unless @pages.nil?
json.contents @contents, :id, :title, :start_date, :end_date, :event_type, :host_organization,
                         :cost, :recurrence, :featured, :links, :pubdate, :authors, 
                         :image, :category, :source_name, :location, :parent_uri
