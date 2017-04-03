# == Schema Information
#
# Table name: promotion_banner_reports
#
#  id                     :integer          not null, primary key
#  promotion_banner_id    :integer
#  report_date            :datetime
#  impression_count       :integer
#  click_count            :integer
#  total_impression_count :integer
#  total_click_count      :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  load_count             :integer
#

class PromotionBannerReport < ActiveRecord::Base
  belongs_to :promotion_banner

  def daily_revenue
    if promotion_banner.cost_per_day.present?
      promotion_banner.cost_per_day
    elsif promotion_banner.cost_per_impression.present?
      promotion_banner.cost_per_impression * (impression_count || 0)
    end
  end
end
