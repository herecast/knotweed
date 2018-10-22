# == Schema Information
#
# Table name: content_reports
#
#  id                       :bigint(8)        not null, primary key
#  content_id               :bigint(8)
#  report_date              :datetime
#  view_count               :integer          default(0)
#  banner_click_count       :integer          default(0)
#  comment_count            :bigint(8)
#  total_view_count         :bigint(8)
#  total_banner_click_count :bigint(8)
#  total_comment_count      :bigint(8)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content_report do
    association :content
    report_date { Time.current }
    view_count { rand(0..100) }
    banner_click_count { rand(0..100) }
    comment_count { rand(0..100) }
  end
end
