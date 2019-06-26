# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) are set in the file config/application.yml.
# See http://railsapps.github.io/rails-environment-variables.html

# create DailyUV Organization
Organization.create!(
  name: 'DailyUV',
  org_type: 'Blog',
  can_publish_news: true,
  description_card_active: true,
  description: Faker::Lorem
)
p "Created 'DailyUV' organization"

locations = []
[
  { id: 19, zip: "05001", city: "White River Junction", state: "VT", default_location: true, consumer_active: true, latitude: 43.6489596, longitude: -72.3192579 },
  { zip: "05055", city: "Norwich", state: "VT", consumer_active: true, latitude: 43.715015, longitude: -72.308441 },
  { zip: "03755", city: "Hanover", state: "NH", consumer_active: true, latitude: 43.702126, longitude: -72.289525 },
  { zip: "05047", city: "Hartford", state: "VT", consumer_active: true, latitude: 43.663913, longitude: -72.369648 },
  { zip: "03784", city: "West Lebanon", state: "NH", consumer_active: true, latitude: 43.6446508, longitude: -72.3106065 },
  { zip: "05088", city: "Wilder", state: "VT", consumer_active: true, latitude: 43.6728484, longitude: -72.3087022 },
  { zip: "05084", city: "West Hartford", state: "VT", consumer_active: true, latitude: 43.7013267, longitude: -72.426983 },
  { zip: "05059", city: "Quechee", state: "VT", consumer_active: true, latitude: 43.646227, longitude: -72.4186105 },
  { zip: "05052", city: "North Hartland", state: "VT", consumer_active: true, latitude: 43.596986, longitude: -72.359722 }
].each do |l_hash|
  locations << FactoryGirl.create(:location, l_hash)
end
locations.each do |location|
  location.update_attribute(
    :location_ids_within_fifty_miles, locations.map(&:id)
  )
end
p 'Created locations'

# create admin account
User.create!(
  name: 'Admin',
  email: 'admin@subtext.org',
  confirmed_at: Time.now,
  password: 'password',
  password_confirmation: 'password',
  location: Location.first,
  test_group: 'subtext'
).add_role(:admin)
p 'Created admin@subtext.org admin user'

# create a test user
u = User.create!(
  name: Faker::Name.name,
  email: Faker::Internet.email,
  confirmed_at: Time.now,
  password: 'password',
  password_confirmation: 'password',
  location: Location.first
)
p "Created test user #{u.email}"

# create a business profile
BusinessLocation.create!(
  name: Faker::Company.name,
  address: Faker::Address.street_address,
  city: Faker::Address.city,
  state: Faker::Address.state_abbr,
  zip: Faker::Address.zip,
  phone: Faker::PhoneNumber.phone_number,
  email: Faker::Internet.email,
  latitude: Location::DEFAULT_LOCATION_COORDS[0],
  longitude: Location::DEFAULT_LOCATION_COORDS[1]
)
BusinessProfile.create!(
  business_location: BusinessLocation.last
)
p "Created business profile for #{BusinessLocation.last.name}"

# quick method to generate some basic content attributes (new each time with Faker)
def base_content_attrs
  {
    title: Faker::Lorem.sentence(4),
    raw_content: Faker::Lorem.paragraph(5),
    authors: Faker::Name.name,
    pubdate: Time.now,
    organization: Organization.last,
    location_id: Location.all.map(&:id).sample,
    created_by: User.last,
    updated_by: User.last
  }
end

6.times do
  FactoryGirl.create :content, :news, base_content_attrs
  FactoryGirl.create :content, :event, base_content_attrs
  FactoryGirl.create :content, :market_post, base_content_attrs
end

p "Created #{Content.count} content records"
