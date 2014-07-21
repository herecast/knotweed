# == Schema Information
#
# Table name: import_locations
#
#  id             :integer          not null, primary key
#  parent_id      :integer          default(0)
#  region_id      :integer          default(0)
#  city           :string(255)
#  state          :string(255)
#  zip            :string(255)
#  country        :string(128)
#  link_name      :string(255)
#  link_name_full :string(255)
#  status         :integer          default(0)
#  usgs_id        :string(128)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

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
