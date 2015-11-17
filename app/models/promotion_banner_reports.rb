class PromotionBannerReports < ActiveRecord::Base
  attr_accessible :click_count, :impression_count, :promotion_banner_id, :report_date, :total_click_count, :total_impression_count
end
