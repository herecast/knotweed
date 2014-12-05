json.page @page unless @page.nil?
json.total_pages @pages unless @pages.nil?

json.contents @contents do |c|
  if params[:start_date_only] # for calendar query
    attrs = Content.start_date_only_fields
  else
    if params[:truncated]
      attrs = Content.truncated_event_fields
      json.content c.raw_content
    else
      attrs = Content.truncated_content_fields
      json.content c.sanitized_content
    end

    # include images except for event calendar query (start_date_only)
    if c.images.present?
      json.image c.images.first.image.url
    end
  end
  
  attrs.each{|attr| json.set! attr, c.send(attr) }
  
end
