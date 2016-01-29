module PromotionsHelper
  extend self
  def get_promotion_list(organization, content)
    if content.nil?
      organization.promotions
    else
      content.promotions
    end
  end

  def new_promotion_link(organization, content)
    if content.nil?
      Rails.application.routes.url_helpers.new_organization_promotion_path(organization)
    else
      Rails.application.routes.url_helpers.new_organization_promotion_path(organization_id: organization.id, content_id: content.id)
    end
  end
end
