# == Schema Information
#
# Table name: locations
#
#  id                              :bigint(8)        not null, primary key
#  zip                             :string(255)
#  city                            :string(255)
#  state                           :string(255)
#  county                          :string(255)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  consumer_active                 :boolean          default(FALSE)
#  is_region                       :boolean          default(FALSE)
#  slug                            :string
#  latitude                        :float
#  longitude                       :float
#  default_location                :boolean          default(FALSE)
#  location_ids_within_five_miles  :integer          default([]), is an Array
#  location_ids_within_fifty_miles :integer          default([]), is an Array
#
# Indexes
#
#  index_locations_on_latitude_and_longitude  (latitude,longitude)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :location do
    zip { Faker::Address.zip }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    county { Faker::Address.city }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    consumer_active true

    after :create do |location|
      location.update_attribute(:location_ids_within_fifty_miles, [location.id])
    end

    trait :default do
      default_location true
      latitude Location::DEFAULT_LOCATION_COORDS[0] 
      longitude Location::DEFAULT_LOCATION_COORDS[1]
    end
  end
end
