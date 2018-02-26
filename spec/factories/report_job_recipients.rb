# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_job_recipient do
    report_job
    report_recipient
  end
end
