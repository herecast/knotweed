# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :publish_job do
    frequency 0
    publish_method Content::EXPORT_TO_XML
  end
end
