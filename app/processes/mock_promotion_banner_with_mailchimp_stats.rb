class MockPromotionBannerWithMailchimpStats

  def initialize(opts)
    @results          = opts[:results]
    @promotion_banner = opts[:promotion_banner]
  end

  def impression_count
    @results[:opens_total]
  end

  def click_count
    @results[:total_clicks]
  end

  def method_missing(method, *args, &block)
    if @promotion_banner.respond_to? method
      @promotion_banner.send method, *args, &block
    else
      super method, *args, &block
    end
  end
end