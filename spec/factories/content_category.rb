FactoryGirl.define do
  factory :content_category do
    sequence(:name) { |n| "Category#{n}" }
  end
end
