# == Schema Information
#
# Table name: organizations
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  org_type     :string(255)
#  notes        :text
#  tagline      :string(255)
#  links        :text
#  social_media :text
#  general      :text
#  header       :string(255)
#  logo         :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    name "MyString"
  end
end
