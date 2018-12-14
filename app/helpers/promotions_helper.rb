module PromotionsHelper
  extend self
  def get_promotion_list(organization, content)
    if content.nil?
      organization.promotions
    else
      content.promotions
    end
  end
end
