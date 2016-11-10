module HasPromotionForBanner
  extend ActiveSupport::Concern

  included do
    belongs_to :promotion
    validate :promotion_exists, if: :promotion_id
    validate :is_valid_promotion_banner, if: :promotion
  end

  private

  def is_valid_promotion_banner
    if promotion
      unless promotion.promotable.is_a? PromotionBanner
        errors.add(:promotion_id, "must be a promotion tied to a banner")
      end
    end
  end

  def promotion_exists
    if promotion_id
      unless promotion
        errors.add(:promotion_id, 'must exist')
      end
    end
  end

end
