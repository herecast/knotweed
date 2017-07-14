# == Schema Information
#
# Table name: organization_content_tags
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  content_id      :integer
#

class OrganizationContentTag < ActiveRecord::Base
  belongs_to :organization
  belongs_to :tagged_content, class_name: 'Content', foreign_key: 'content_id'
end
