class Publication < ActiveRecord::Base
  
  has_many :issues
  belongs_to :organization
  
  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id
  
  mount_uploader :logo, ImageUploader
end
