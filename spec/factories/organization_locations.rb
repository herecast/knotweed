# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_locations
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  location_id     :integer
#  location_type   :string
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_organization_locations_on_location_id      (location_id)
#  index_organization_locations_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organization_id => organizations.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization_location do
    organization
    location
  end
end
