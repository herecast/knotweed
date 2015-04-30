# == Schema Information
#
# Table name: promotions
#
#  id              :integer          not null, primary key
#  active          :boolean
#  publication_id  :integer
#  content_id      :integer
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :integer
#  promotable_type :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion do
    active true
    content 
    description "What a terrible promotion"
  end
end
