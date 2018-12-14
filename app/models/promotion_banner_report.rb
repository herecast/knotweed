# == Schema Information
#
# Table name: promotion_banner_reports
#
#  id                     :bigint(8)        not null, primary key
#  promotion_banner_id    :bigint(8)
#  report_date            :datetime
#  impression_count       :bigint(8)
#  click_count            :bigint(8)
#  total_impression_count :bigint(8)
#  total_click_count      :bigint(8)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  load_count             :integer
#
# Indexes
#
#  index_promotion_banner_reports_on_promotion_banner_id  (promotion_banner_id)
#  index_promotion_banner_reports_on_report_date          (report_date)
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
