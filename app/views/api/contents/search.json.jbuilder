attrs = [:id, :title, :start_date, :end_date, :event_type, :host_organization, :cost, :recurrence,
         :featured, :links, :pubdate, :authors, :category, :publication_name, :location, 
         :parent_uri]

json.page @page unless @page.nil?
json.total_pages @pages unless @pages.nil?
json.contents @contents do |c|
  json.score c.weight
  json.partial! 'api/contents/partials/content', content: c, without_attributes: [:content, :title]
  json.content fix_ts_excerpt(c.excerpts.content)
  json.title fix_ts_excerpt(c.excerpts.title)
end
