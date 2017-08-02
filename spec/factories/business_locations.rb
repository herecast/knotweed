# == Schema Information
#
# Table name: business_locations
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  address             :string(255)
#  phone               :string(255)
#  email               :string(255)
#  hours               :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#  latitude            :float
#  longitude           :float
#  venue_url           :string(255)
#  locate_include_name :boolean          default(FALSE)
#  city                :string(255)
#  state               :string(255)
#  zip                 :string(255)
#  status              :string(255)
#  created_by          :integer
#  updated_by          :integer
#  service_radius      :decimal(10, )
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_location do
    name { Faker::Company.name }
    organization
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip { Faker::Address.zip }
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    hours ['Mo-Fr 08:00-17:00']
    latitude { Location::DEFAULT_LOCATION_COORDS[0] }
    longitude { Location::DEFAULT_LOCATION_COORDS[1] }
  end
end
