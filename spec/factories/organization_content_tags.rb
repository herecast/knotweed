# == Schema Information
#
# Table name: organization_content_tags
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  content_id      :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization_content_tag do
  end
end
