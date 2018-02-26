# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_recipient do
    report
    user
  end
end
