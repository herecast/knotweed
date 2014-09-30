attrs = [:id, :title, :start_date, :end_date, :event_type, :host_organization, :cost, :recurrence,
         :featured, :links, :pubdate, :authors, :category, :source_name, :source_id, :location, 
         :parent_uri, :business_location, :category_reviewed, :has_active_promotion, :content]
attrs.reject!{|a| without_attributes.include? a } if defined? without_attributes
attrs.merge!(without_attributes)if defined? with_attributes

attrs.each{|attr| json.set! attr, content.send(attr) }
if content.images.present?
  json.image content.images.first.image.url
end
