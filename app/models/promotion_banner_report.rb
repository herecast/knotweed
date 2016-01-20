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
#

class PromotionBannerReport < ActiveRecord::Base
  belongs_to :promotion_banner

  attr_accessible :click_count, :impression_count, :promotion_banner_id, 
    :report_date, :total_click_count, :total_impression_count
end
