# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import_location do
    city "Norwich"
    state "VT"
    zip "05055"
    country "USA"
    link_name "NORWICH VT"
    link_name_full "NORWICH VERMONT"
    region_id 1
  end
end
