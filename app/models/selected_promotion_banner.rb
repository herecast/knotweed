class SelectedPromotionBanner
  attr_reader :promotion_banner
  attr_reader :select_score
  attr_reader :select_method

  def initialize(promotion_banner, select_score:, select_method:)
    @promotion_banner = promotion_banner
    @select_score = select_score
    @select_method = select_method
  end

  def method_missing(method, *args, &block)
    if respond_to?(method)
      send(method, *args, &block)
    elsif promotion_banner.respond_to?(method)
      promotion_banner.send(method, *args, &block)
    else
      super
    end
  end

  def read_attribute_for_serialization attr
    send(attr)
  end
end
