# == Schema Information
#
# Table name: annotation_reports
#
#  id            :integer          not null, primary key
#  content_id    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  name          :string(255)
#  description   :text
#  json_response :text
#  repository_id :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :annotation_report do
    repository
    content
  end
end
