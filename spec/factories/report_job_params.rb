# == Schema Information
#
# Table name: report_job_params
#
#  id                        :integer          not null, primary key
#  report_job_paramable_type :string
#  report_job_paramable_id   :integer
#  param_name                :string
#  param_value               :string
#  created_by                :integer
#  updated_by                :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  report_job_params_paramable_type_id  (report_job_paramable_type,report_job_paramable_id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_job_param do
    association :report_job_paramable, factory: :report
    sequence(:param_name) {|n| "param-#{n}" }
    param_value "test report"
  end
end
