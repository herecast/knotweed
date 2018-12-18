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

class OrganizationContentTag < ActiveRecord::Base
  belongs_to :organization
  belongs_to :tagged_content, class_name: 'Content', foreign_key: 'content_id'
end
