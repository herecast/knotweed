# == Schema Information
#
# Table name: promotion_banners
#
#  id               :integer          not null, primary key
#  banner_image     :string(255)
#  redirect_url     :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  campaign_start   :datetime
#  campaign_end     :datetime
#  max_impressions  :integer
#  impression_count :integer          default(0)
#  click_count      :integer          default(0)
#  daily_max_impressions :integer
#
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion_banner do
    promotion
    redirect_url "http://www.google.com"
    campaign_start 1.day.ago
    campaign_end 1.day.from_now
    max_impressions 100
    daily_max_impressions 5
    impression_count 0
  end
end
