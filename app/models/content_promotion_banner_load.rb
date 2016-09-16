# == Schema Information
#
# Table name: content_promotion_banner_loads
#
#  id                  :integer          not null, primary key
#  content_id          :integer
#  promotion_banner_id :integer
#  load_count          :integer          default(1)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  select_method       :string(255)
#  select_score        :float
#

class ContentPromotionBannerLoad < ActiveRecord::Base
  attr_accessible :content_id, :load_count, :promotion_banner_id, :select_method, :select_score

  belongs_to :content
  belongs_to :promotion_banner

  # looks for a corresponding ContentPromotionBannerImpression record --
  # if it finds it, increment display_count, else create a new one.
  def self.log_load(content_id, promotion_banner_id, select_method, select_score)
    impression = self.where(content_id: content_id,
                                promotion_banner_id: promotion_banner_id).first
    if impression.present?
      impression.update_attribute :load_count, impression.load_count+1
      impression.update_attribute :select_method, select_method
      impression.update_attribute :select_score, select_score
    else
      self.create(content_id: content_id,
             promotion_banner_id: promotion_banner_id, load_count: 1, select_method: select_method, select_score: select_score)
    end
  end

end