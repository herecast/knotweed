# == Schema Information
#
# Table name: features
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  active      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  options     :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feature do
    sequence(:name) { |n| "My Feature Toggle #{n}" }
    description "This is the feature description"
    active false
  end
end
