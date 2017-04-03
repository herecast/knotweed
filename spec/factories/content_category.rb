FactoryGirl.define do
  factory :content_category do
    sequence(:name) { |n| "Category#{n}" }

    trait :talk do
      name 'talk_of_the_town'
    end
  end
end
