module HasPromotionForBanner
  extend ActiveSupport::Concern

  included do
    validate :promotions_exists, if: :promotion_ids?
    validate :is_valid_promotion_banner, if: :promotion_ids_changed?
  end

  private

  def is_valid_promotion_banner
    unless promotions.all? { |promo| promo.promotable.is_a? PromotionBanner }
      errors.add(:promotion_ids, "you have one or more promotions without a banner")
    end
  end

  def promotions_exists
    if promotion_ids.any?
      unless promotions.any?
        errors.add(:promotion_ids, 'must exist')
      end
    end
  end

end
