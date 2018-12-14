# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_content_tags
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  content_id      :integer
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_organization_content_tags_on_content_id       (content_id)
#  index_organization_content_tags_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (content_id => contents.id)
#  fk_rails_...  (organization_id => organizations.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization_content_tag do
  end
end
