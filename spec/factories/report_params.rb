# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_param do
    association :report
    report_param_type :report
    sequence(:param_name) {|n| "param-#{n}" }
    param_value "Test Report"
  end
end
