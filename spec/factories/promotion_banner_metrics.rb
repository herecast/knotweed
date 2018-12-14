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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion_banner_metric do
    promotion_banner
    event_type 'impression'
  end
end
