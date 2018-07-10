# == Schema Information
#
# Table name: organization_content_tags
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  content_id      :integer
#
# Indexes
#
#  index_organization_content_tags_on_content_id       (content_id)
#  index_organization_content_tags_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_0359aae08c  (organization_id => organizations.id)
#  fk_rails_36c5dda2b4  (content_id => contents.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization_content_tag do
  end
end
