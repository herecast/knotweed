# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_locations
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  location_id     :integer
#  location_type   :string
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_organization_locations_on_location_id      (location_id)
#  index_organization_locations_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organization_id => organizations.id)
#

class OrganizationLocation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :location

  TYPES = ['base'].freeze

  scope :base, -> { where(location_type: 'base') }

  after_save if: :saved_changes? do
    organization.trigger_content_reindex!
  end

  after_destroy do
    organization.trigger_content_reindex!
  end

  def base?
    'base'.eql? location_type
  end

  def base!
    self.location_type = 'base'
    save!
  end
end
