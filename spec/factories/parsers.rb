# == Schema Information
#
# Table name: parsers
#
#  id              :integer          not null, primary key
#  filename        :string(255)
#  organization_id :integer
#  name            :string(255)
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parser do
    sequence (:filename) { |n| "parser-#{n}.rb" }
    name "My Parser"
  end
end
