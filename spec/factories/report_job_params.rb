# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_job_param do
    association :report_job_paramable, factory: :report
    sequence(:param_name) {|n| "param-#{n}" }
    param_value "test report"
  end
end
