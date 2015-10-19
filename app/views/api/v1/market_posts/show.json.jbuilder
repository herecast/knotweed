json.market_posts [@market_post] do |mp|
  attrs = [:id, :contact_email, :contact_phone, :contact_url, :cost, :latitude,
    :locate_address, :locate_include_name, :locate_name, :longitude]
  content_attrs = [:title, :pubdate, :authors, :category, :parent_category, :publication_name, 
                  :publication_id, :parent_uri, :category_reviewed, :has_active_promotion, 
                  :authoremail, :subtitle]
  json.content_id mp.content.id
  json.content mp.content.raw_content

  json.comments @comments do |comment|
    json.partial! 'api/v1/comments/partials/comment', comment: comment unless comment.nil?
  end

  if mp.content.images.present?
    json.image mp.content.primary_image.image.url
    json.image_caption mp.content.primary_image.caption
    json.image_credit mp.content.primary_image.credit
  end

  attrs.each{|attr| json.set! attr, mp.send(attr) }
  content_attrs.each{|attr| json.set! attr, mp.content.send(attr) }
end
