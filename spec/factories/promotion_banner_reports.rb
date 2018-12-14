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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion_banner_report do
    association :promotion_banner
    report_date { Time.current }
    impression_count { rand(0..100) }
    click_count { rand(0..100) }
  end
end
