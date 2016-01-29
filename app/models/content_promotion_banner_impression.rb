# == Schema Information
#
# Table name: content_promotion_banner_impressions
#
#  id                  :integer          not null, primary key
#  content_id          :integer
#  promotion_banner_id :integer
#  display_count       :integer          default(1)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  select_method       :string(255)
#  select_score        :float
#

class ContentPromotionBannerImpression < ActiveRecord::Base
  attr_accessible :content_id, :display_count, :promotion_banner_id, :select_method, :select_score

  belongs_to :content
  belongs_to :promotion_banner

  # looks for a corresponding ContentPromotionBannerImpression record --
  # if it finds it, increment display_count, else create a new one.
  def self.log_impression(content_id, promotion_banner_id, select_method, select_score)
    impression = ContentPromotionBannerImpression.where(content_id: content_id,
                                promotion_banner_id: promotion_banner_id).first
    if impression.present?
      impression.update_attribute :display_count, impression.display_count+1
      impression.update_attribute :select_method, select_method
      impression.update_attribute :select_score, select_score
    else
      ContentPromotionBannerImpression.create(content_id: content_id, 
             promotion_banner_id: promotion_banner_id, display_count: 1, select_method: select_method, select_score: select_score)
    end
  end

end
