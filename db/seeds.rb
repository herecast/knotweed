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
Organization.create!({
  name: "DailyUV",
  org_type: 'Blog',
  can_publish_news: true,
  description_card_active: true,
  description: Faker::Lorem
})
p "Created 'DailyUV' organization"

FactoryGirl.create :location, :default
p "Created default location"

# create admin account
User.create!({
  name: 'Admin',
  email: 'admin@subtext.org',
  confirmed_at: Time.now,
  password: 'password',
  password_confirmation: 'password',
  location: Location.first,
  test_group: 'subtext'
}).add_role(:admin)
p "Created admin@subtext.org admin user"

# create a test user
u = User.create!({
  name: Faker::Name.name,
  email: Faker::Internet.email,
  confirmed_at: Time.now,
  password: 'password',
  password_confirmation: 'password',
  location: Location.first
})
p "Created test user #{u.email}"

# quick method to generate some basic content attributes (new each time with Faker)
def base_content_attrs
  {
    title: Faker::Lorem.sentence(4),
    raw_content: Faker::Lorem.paragraph(5),
    authors: Faker::Name.name,
    pubdate: Time.now,
    organization: Organization.last,
    location_id: Location.first.id,
    created_by: User.last,
    updated_by: User.last
  }
end

# create a 'talk' record
Content.create!(base_content_attrs.merge({
  content_category: ContentCategory.create!({ name: 'talk_of_the_town' }),
  channel: Comment.new,
}))

# create a 'news' record
Content.create!(base_content_attrs.merge({
  content_category: ContentCategory.create!({ name: 'news' }),
}))

# create a 'market_post' record
Content.create!(base_content_attrs.merge({
  content_category: ContentCategory.create!({ name: 'market' }),
  channel: MarketPost.new
}))

# create an 'event' record
Content.create!(base_content_attrs.merge({
  content_category: ContentCategory.create({ name: 'event' }),
  channel: Event.new(
    event_instances: [EventInstance.new(start_date: 1.week.from_now)]
  )
}))

p "Created #{Content.count} content records"

# create a business profile
BusinessLocation.create!({
  name: Faker::Company.name,
  address: Faker::Address.street_address,
  city: Faker::Address.city,
  state: Faker::Address.state_abbr,
  zip: Faker::Address.zip,
  phone: Faker::PhoneNumber.phone_number,
  email: Faker::Internet.email,
  latitude: Location::DEFAULT_LOCATION_COORDS[0],
  longitude: Location::DEFAULT_LOCATION_COORDS[1],
})
BusinessProfile.create!({
  business_location: BusinessLocation.last
})
p "Created business profile for #{BusinessLocation.last.name}"
