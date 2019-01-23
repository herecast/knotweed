# frozen_string_literal: true

class SelectedPromotionBanner
  attr_reader :promotion_banner
  attr_reader :id
  attr_reader :promotion
  attr_reader :select_score
  attr_reader :select_method

  def initialize(promotion_banner, select_score:, select_method:)
    @promotion_banner = promotion_banner
    @id = promotion_banner.id
    @promotion = promotion_banner.try(:promotion)
    @select_score = select_score
    @select_method = select_method
  end

  def read_attribute_for_serialization(attr)
    send(attr)
  end
end
