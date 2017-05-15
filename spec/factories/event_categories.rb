# == Schema Information
#
# Table name: event_categories
#
#  id             :integer          not null, primary key
#  name           :string
#  query          :string
#  query_modifier :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  slug           :string
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_category do
    name "MyString"
    query "test query"
  end
end
