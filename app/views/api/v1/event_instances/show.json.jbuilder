json.events [@event_instance] do |ei|
  attrs = [:id, :sponsor, :cost, :featured, :links, :venue, :event_url, 
          :sponsor_url, :subtitle, :contact_phone, :contact_email, :contact_url]
  content_attrs = [:title, :pubdate, :authors, :category, :parent_category, :publication_name, 
                  :publication_id, :parent_uri, :category_reviewed, :has_active_promotion, 
                  :authoremail, :subtitle]
  json.event_id ei.event.id
  json.content_id ei.event.content.id
  json.content ei.event.content.raw_content

  json.comments @comments do |comment|
    json.partial! 'api/v1/comments/partials/comment', comment: comment unless comment.nil?
  end

  if ei.event.content.images.present?
    json.image ei.event.content.images.first.image.url
  end

  attrs.each{|attr| json.set! attr, ei.event.send(attr) }
  content_attrs.each{|attr| json.set! attr, ei.event.content.send(attr) }
  json.event_instances @event_instance.event.event_instances
end
