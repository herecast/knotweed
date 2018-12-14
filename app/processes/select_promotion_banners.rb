class SelectPromotionBanners
  def self.call(*args)
    self.new(*args).call
  end

  def initialize(opts = {})
    @opts            = opts
    @banners         = []
    @exclude         = opts[:exclude] || []
    @not_run_of_site = true
  end

  def call
    if global_banner_override
      return global_banner_override
    end

    promotion_banner_loop
    get_random_promotion unless @banners.length == (@opts[:limit] || 1) || @not_run_of_site
    @banners
  end

  private

  def promotion_banner_loop
    if @opts[:promotion_id].present?
      get_direct_promotion(@opts[:promotion_id])
    elsif @opts[:content_id].present?
      get_related_promotion
    elsif @opts[:organization_id].present?
      organization = Organization.find @opts[:organization_id]
      get_organization_promotion(organization)
    else
      @not_run_of_site = false
    end
  end

  def promotion_banners_needed
    (@opts[:limit].try(:to_i) || 1) - @banners.length
  end

  def add_promotion(selected_promo)
    if selected_promo.try(:promotion_banner)
      unless @exclude.include? selected_promo.id
        @banners << selected_promo
        @exclude << selected_promo.id
      end
    end
  end

  def get_direct_promotion(promotion_id)
    promotion = Promotion.find_by(id: promotion_id)
    if promotion && promotion.promotable.is_a?(PromotionBanner) && promotion.promotable.active_with_inventory?
      add_promotion(SelectedPromotionBanner.new(
                      promotion.promotable,
                      select_score: nil,
                      select_method: 'sponsored_content'
                    ))
    else
      @not_run_of_site = false
      get_random_promotion
    end
  end

  def get_related_promotion
    content = Content.find @opts[:content_id]
    if content.banner_ad_override.present?
      get_direct_promotion(content.banner_ad_override)
    elsif content.organization.banner_ad_override? && @not_run_of_site
      get_organization_promotion(content.organization)
    else
      @not_run_of_site = false
    end
  end

  def get_organization_promotion(organization)
    if organization.banner_ad_override.present?
      # TODO: this is really dependent on banner_ad_override being populated properly
      ids = organization.banner_ad_override.split(/,[\s]*?/)
      banner = PromotionBanner.for_promotions(ids).active.has_inventory.order('random()').first
      if banner.present?
        add_promotion(SelectedPromotionBanner.new(
                        banner,
                        select_score: nil,
                        select_method: 'sponsored_content'
                      ))
      else
        @not_run_of_site = false
        get_related_promotion
      end
    end
  end

  def get_random_promotion
    query = PromotionBanner.active.run_of_site.order('RANDOM()')

    banners = query.boost.has_inventory.limit(promotion_banners_needed).where.not(id: @exclude)
    banners.each do |banner|
      add_promotion(SelectedPromotionBanner.new(
                      banner,
                      select_score: nil,
                      select_method: 'boost'
                    ))
    end

    unless promotion_banners_needed == 0
      banners = query.has_inventory.limit(promotion_banners_needed).where.not(id: @exclude)
      banners.each do |banner|
        add_promotion(SelectedPromotionBanner.new(
                        banner,
                        select_score: nil,
                        select_method: 'active'
                      ))
      end
    end

    unless promotion_banners_needed == 0
      banners = query.limit(promotion_banners_needed).where.not(id: @exclude)
      banners.each do |banner|
        add_promotion(SelectedPromotionBanner.new(
                        banner,
                        select_score: nil,
                        select_method: 'active no inventory'
                      ))
      end
    end
  end

  def global_banner_override
    feature = Feature.find_by(name: 'global-banner-override', active: true)

    if feature
      return @banners if @banners.any?

      ids = JSON.parse(feature.options)
      promos = Promotion.find(ids)

      banners = promos.collect(&:promotable).select { |p| p.is_a? PromotionBanner }

      if banners.count > 0
        limit = @opts[:limit] || 1

        while @banners.count < limit.to_i
          @banners << SelectedPromotionBanner.new(
            banners.sample,
            select_score: nil,
            select_method: 'global-banner-override'
          )
        end
      end

      return @banners
    else
      return nil;
    end
  rescue nil
  end
end
