class OrganizationLocation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :location

  TYPES = ['base']

  scope :base,-> { where(location_type: 'base') }

  after_save if: :changed? do
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
    self.save!
  end
end
