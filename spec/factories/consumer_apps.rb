# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :consumer_app do
    name "Test App"
    uri "http://23.92.16.168:1234"
  end
end
