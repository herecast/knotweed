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
#

class PromotionBannerMetric < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  belongs_to :promotion_banner
  validates_presence_of :promotion_banner
end
