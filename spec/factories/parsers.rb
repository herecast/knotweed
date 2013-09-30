# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parser do
    sequence (:filename) { |n| "parser-#{n}.rb" }
    name "My Parser"
  end
end
