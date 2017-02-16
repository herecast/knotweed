class SelectPromotionBanners

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(opts={})
    @opts            = opts
    @banners         = []
    @exclude         = opts[:exclude] || []
    @not_run_of_site = true
  end

  def call
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

    def add_promotion(set)
      unless @exclude.include? set[0].id
        @banners << set
        @exclude << set[0].id
      end
    end

    def get_direct_promotion(promotion_id)
      promotion = Promotion.find_by(id: promotion_id)
      if promotion && promotion.promotable.is_a?(PromotionBanner) && promotion.promotable.active?
        add_promotion([promotion.promotable, nil, 'sponsored_content'])
      end
    end

    def get_related_promotion
      content = Content.find @opts[:content_id]
      if content.banner_ad_override.present?
        get_direct_promotion(content.banner_ad_override)
      elsif content.organization.banner_ad_override?
        get_organization_promotion(content.organization)
      else
        @not_run_of_site = false
        # use DspService to return active, relevant ads w/inventory over a certain threshold score
        results = DspService.get_related_promo_ids(content, @opts[:limit], @opts[:repository])
        results = results.sample(promotion_banners_needed)

        if results.present?
          results.each do |result|
            content_id = result['id'].split('/')[-1].to_i
            if content_id.present?
              banner = PromotionBanner.for_content(content_id)
                                      .active.has_inventory
                                      .run_of_site
                                      .order('random()')
                                      .first
            end
            if banner.present?
              add_promotion([banner, result['score'].try(:to_s), 'relevance'])
            end
          end
        end
      end
    end

    def get_organization_promotion(organization)
      if organization.banner_ad_override.present?
        ids = organization.banner_ad_override.split(/,[\s]*?/)
        get_direct_promotion(ids.sample)
      end
    end

    def get_random_promotion
      query = PromotionBanner.active.run_of_site.order('RANDOM()')

      banners = query.boost.has_inventory.limit(promotion_banners_needed).where.not(id: @exclude)
      banners.each do |banner|
        add_promotion([banner, nil, 'boost'])
      end

      unless promotion_banners_needed == 0
        banners = query.paid.has_inventory.limit(promotion_banners_needed).where.not(id: @exclude)
        banners.each do |banner|
          add_promotion([banner, nil, 'paid active'])
        end
      end

      unless promotion_banners_needed == 0
        banners = query.has_inventory.limit(promotion_banners_needed).where.not(id: @exclude)
        banners.each do |banner|
          add_promotion([banner, nil, 'active'])
        end
      end

      unless promotion_banners_needed == 0
        banners = query.limit(promotion_banners_needed).where.not(id: @exclude)
        banners.each do |banner|
          add_promotion([banner, nil, 'active no inventory'])
        end
      end
    end

end
