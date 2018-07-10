# == Schema Information
#
# Table name: content_locations
#
#  id            :integer          not null, primary key
#  content_id    :integer
#  location_id   :integer
#  location_type :string
#  created_at    :datetime
#  updated_at    :datetime
#
# Indexes
#
#  index_content_locations_on_content_id   (content_id)
#  index_content_locations_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_9ca11decb0  (content_id => contents.id)
#  fk_rails_cc6f358347  (location_id => locations.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content_location do
    content
    location
  end
end
