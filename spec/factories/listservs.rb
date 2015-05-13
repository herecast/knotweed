# == Schema Information
#
# Table name: listservs
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  reverse_publish_email :string(255)
#  import_name           :string(255)
#  active                :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv do
    name "My Listserv"
    sequence(:reverse_publish_email) { |n| "mylistserv#{n}@vclab.net" }
    active true
  end
end
