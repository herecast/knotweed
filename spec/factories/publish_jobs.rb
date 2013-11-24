# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :publish_job do
    frequency 0
    publish_method PublishJob::EXPORT_TO_XML
  end
end
