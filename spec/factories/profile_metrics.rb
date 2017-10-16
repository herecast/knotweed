# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :profile_metric do
    organization nil
    location nil
    user nil
    content nil
    event_type "MyString"
    user_ip "MyString"
    user_agent "MyString"
    client_id "MyString"
    location_confirmed false
  end
end
