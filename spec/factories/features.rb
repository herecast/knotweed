# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feature do
    sequence(:name) { |n| "My Feature Toggle #{n}"}
    description "This is the feature description"
    active false
  end
end
