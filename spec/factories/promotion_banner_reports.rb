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
