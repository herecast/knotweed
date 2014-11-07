# we need to provide different attributes if it is a "truncated" query
if params[:truncated]
  attrs = [:id, :title, :subtitle, :start_date, :event_type, :host_organization,
           :event_title, :event_description, :business_location]
  json.content content.raw_content
else
  attrs = [:id, :title, :start_date, :end_date, :event_type, :host_organization, :cost, :recurrence,
           :featured, :links, :pubdate, :authors, :category, :parent_category, :source_name, :source_id, :location, 
           :parent_uri, :business_location, :category_reviewed, :has_active_promotion, :authoremail, :event_title,
           :event_description, :event_url, :sponsor_url, :subtitle]
  json.content content.sanitized_content
end
attrs.reject!{|a| without_attributes.include? a } if defined? without_attributes
attrs.merge!(without_attributes) if defined? with_attributes

attrs.each{|attr| json.set! attr, content.send(attr) }
if content.images.present?
  json.image content.images.first.image.url
end
