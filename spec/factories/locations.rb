# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :location do
    city "Norwich"
    state "VT"
    zip "05055"
    country "USA"
    link_name "NORWICH VT"
    link_name_full "NORWICH VERMONT"
  end
end
