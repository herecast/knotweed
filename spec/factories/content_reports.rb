# == Schema Information
#
# Table name: content_reports
#
#  id                       :integer          not null, primary key
#  content_id               :integer
#  report_date              :datetime
#  view_count               :integer
#  banner_click_count       :integer
#  comment_count            :integer
#  total_view_count         :integer
#  total_banner_click_count :integer
#  total_comment_count      :integer
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
