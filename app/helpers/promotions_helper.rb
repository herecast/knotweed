module PromotionsHelper
  extend self
  def get_promotion_list(publication, content)
    if content.nil?
      publication.promotions
    else
      content.promotions
    end
  end

  def new_promotion_link(publication, content)
    if content.nil?
      Rails.application.routes.url_helpers.new_publication_promotion_path(publication)
    else
      Rails.application.routes.url_helpers.new_publication_promotion_path(publication_id: publication.id, content_id: content.id)
    end
  end
end
