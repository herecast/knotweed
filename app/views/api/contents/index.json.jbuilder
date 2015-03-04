json.page @page unless @page.nil?
json.total_pages @pages unless @pages.nil?

json.contents @contents do |c|
  attrs = Content.truncated_content_fields
  json.content c.sanitized_content

  if c.images.present?
    json.image c.images.first.image.url
  end
  
  attrs.each{|attr| json.set! attr, c.send(attr) }
end
