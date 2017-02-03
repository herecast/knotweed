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
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion_banner_metric do
    promotion_banner
  end
end
