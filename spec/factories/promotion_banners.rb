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
#  load_count             :integer          default(0)
#  integer                :integer          default(0)
#  promotion_type         :string
#  cost_per_impression    :float
#  cost_per_day           :float
#  coupon_email_body      :text
#  coupon_image           :string
#  sales_agent            :string
#  digest_emails          :integer
#

FactoryGirl.define do
  factory :promotion_banner do
    ignore do
      content nil
      created_by nil
    end

    promotion
    redirect_url "http://www.google.com"
    campaign_start 2.days.ago
    campaign_end 2.days.from_now
    max_impressions 1000
    daily_max_impressions 100
    impression_count 5
    click_count 3
    daily_impression_count 0
    digest_emails 2
    banner_image { File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg')) }

    promotion_type PromotionBanner::RUN_OF_SITE # default

    trait :inactive do
      campaign_start 1.week.ago
      campaign_end 6.days.ago
    end

    trait :active do
      campaign_start 1.week.ago
      campaign_end 1.week.from_now
    end

    trait :run_of_site do
      promotion_type PromotionBanner::RUN_OF_SITE
    end
    trait :sponsored do
      promotion_type PromotionBanner::SPONSORED
    end
    trait :digest do
      promotion_type PromotionBanner::DIGEST
    end
    trait :digest do
      promotion_type PromotionBanner::NATIVE
    end

    after(:build) do |e, evaluator|
      e.promotion.content = evaluator.content if evaluator.content.present?
      e.promotion.created_by = evaluator.created_by if evaluator.created_by.present?
    end

  end
end
