# == Schema Information
#
# Table name: promotion_banner_metrics
#
#  id                  :integer          not null, primary key
#  promotion_banner_id :integer
#  event_type          :string
#  content_id          :integer
#  select_method       :string
#  select_score        :float
#  user_id             :integer
#  location            :string
#  page_url            :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  gtm_blocked         :boolean
#  user_agent          :string
#  user_ip             :string
#  page_placement      :string
#  client_id           :string
#  location_id         :integer
#  load_time           :float
#  location_confirmed  :boolean          default(FALSE)
#
# Indexes
#
#  index_promotion_banner_metrics_on_content_id           (content_id)
#  index_promotion_banner_metrics_on_created_at           (created_at)
#  index_promotion_banner_metrics_on_event_type           (event_type)
#  index_promotion_banner_metrics_on_promotion_banner_id  (promotion_banner_id)
#

class PromotionBannerMetric < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  belongs_to :promotion_banner
  belongs_to :content
  validates_presence_of :promotion_banner

  scope :for_payment_period, ->(period_start, period_end) {
    where(
      created_at: period_start.beginning_of_day..period_end.end_of_day,
      event_type: 'impression'
    ).
    where('content_id IS NOT NULL')
  }

end
