# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :publish_record do
    publish_job nil
    items_published 1
    failures 1
  end
end
