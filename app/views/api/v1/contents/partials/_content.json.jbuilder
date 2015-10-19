attrs = [:id, :title, :pubdate, :authors, :category, :parent_category, :publication_name, :publication_id, :location,
         :parent_uri, :category_reviewed, :has_active_promotion, :authoremail,
         :subtitle, :externally_visible, :channel_type, :channel_id, :location_ids]
json.content content.sanitized_content

if content.channel_type == "Event"
  # this is an awkward  hack to allow us to redirect to events
  # from the similarity stack on consumer side,
  # where we have no knowledge of instances
  json.first_instance_id content.channel.event_instances.first.id
end

if content.images.present?
  json.image content.primary_image.image.url
  json.image_caption content.primary_image.caption
  json.image_credit content.primary_image.credit
end

attrs.reject!{|a| without_attributes.include? a } if defined? without_attributes
attrs.merge!(without_attributes) if defined? with_attributes
attrs.each{|attr| json.set! attr, content.send(attr) }

# merge publication locations with content locations
cl = content.location_ids
pl = content.publication.location_ids
merge = cl | pl
json.location_ids merge
