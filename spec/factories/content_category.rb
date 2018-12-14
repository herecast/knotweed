# frozen_string_literal: true

FactoryGirl.define do
  factory :content_category do
    sequence(:name) { |n| "Category#{n}" }

    trait :talk do
      name 'talk_of_the_town'
    end

    trait :market do
      name 'market'
    end

    trait :event do
      name 'event'
    end

    trait :news do
      name 'news'
    end
  end
end
