attrs = [:id, :title, :pubdate, :authors, :category, :parent_category, :source_name, :source_id, :location, 
         :parent_uri, :category_reviewed, :has_active_promotion, :authoremail, 
         :subtitle, :channelized, :externally_visible]
json.content content.sanitized_content

if content.event.present?
  json.event_id content.event.id
  # this is a shitty hack to allow us to redirect to events
  # from the similarity stack on consumer side,
  # where we have no knowledge of instances
  json.first_instance_id content.event.event_instances.first.id
end

if content.images.present?
  json.image content.images.first.image.url
end

attrs.reject!{|a| without_attributes.include? a } if defined? without_attributes
attrs.merge!(without_attributes) if defined? with_attributes
attrs.each{|attr| json.set! attr, content.send(attr) }
