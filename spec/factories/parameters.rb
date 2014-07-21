# == Schema Information
#
# Table name: parameters
#
#  id         :integer          not null, primary key
#  parser_id  :integer
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parameter do
    parser
    sequence(:name) { |n| "Param-#{n}" }
  end
end
