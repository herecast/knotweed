# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :location do
    city "City"
    state "State"
    zip "55555"
  end
end
