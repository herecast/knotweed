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
#  fk_rails_0359aae08c  (organization_id => organizations.id)
#  fk_rails_36c5dda2b4  (content_id => contents.id)
#

class OrganizationContentTag < ActiveRecord::Base
  belongs_to :organization
  belongs_to :tagged_content, class_name: 'Content', foreign_key: 'content_id'
end
