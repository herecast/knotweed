# == Schema Information
#
# Table name: promotion_banners
#
#  id                     :integer          not null, primary key
#  banner_image           :string(255)
#  redirect_url           :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_start         :date
#  campaign_end           :date
#  max_impressions        :integer
#  impression_count       :integer          default(0)
#  click_count            :integer          default(0)
#  daily_max_impressions  :integer
#  boost                  :boolean          default(FALSE)
#  daily_impression_count :integer          default(0)
#

FactoryGirl.define do
  factory :promotion_banner do
    promotion
    redirect_url "http://www.google.com"
    campaign_start 2.days.ago
    campaign_end 2.days.from_now
    max_impressions 1000
    daily_max_impressions 100
    impression_count 0
    daily_impression_count 0
  end
end
