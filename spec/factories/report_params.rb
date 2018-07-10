# == Schema Information
#
# Table name: report_params
#
#  id                :integer          not null, primary key
#  report_id         :integer
#  report_param_type :string
#  param_name        :string
#  param_value       :string
#  created_by        :integer
#  updated_by        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_param do
    association :report
    report_param_type :report
    sequence(:param_name) {|n| "param-#{n}" }
    param_value "Test Report"
  end
end
