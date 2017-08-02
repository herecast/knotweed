class OrganizationLocation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :location

  TYPES = ['base']

  scope :base,-> { where(location_type: 'base') }

  def base?
    'base'.eql? location_type
  end

  def base!
    self.location_type = 'base'
    self.save!
  end
end
