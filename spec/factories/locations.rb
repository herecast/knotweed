# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  zip             :string(255)
#  city            :string(255)
#  state           :string(255)
#  county          :string(255)
#  latitude            :float
#  longitude           :float
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  consumer_active :boolean          default(FALSE)
#  is_region       :boolean          default(FALSE)
#  slug            :string
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

    trait :default do
      id Location::REGION_LOCATION_ID
      city Location::DEFAULT_LOCATION
      latitude Location::DEFAULT_LOCATION_COORDS[0]
      longitude Location::DEFAULT_LOCATION_COORDS[1]
    end
  end
end
