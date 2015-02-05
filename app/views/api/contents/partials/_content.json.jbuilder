attrs = [:id, :title, :start_date, :end_date, :event_type, :host_organization, :cost, :recurrence,
         :featured, :links, :pubdate, :authors, :category, :parent_category, :source_name, :source_id, :location, 
         :parent_uri, :business_location, :category_reviewed, :has_active_promotion, :authoremail, :event_title,
         :event_description, :event_url, :sponsor_url, :subtitle, :externally_visible]
json.content content.sanitized_content

if content.images.present?
  json.image content.images.first.image.url
end

attrs.reject!{|a| without_attributes.include? a } if defined? without_attributes
attrs.merge!(without_attributes) if defined? with_attributes
attrs.each{|attr| json.set! attr, content.send(attr) }
