class Publication < ActiveRecord::Base
  
  has_many :issues
  
  attr_accessible :name, :logo, :logo_cache, :remove_logo
  
  mount_uploader :logo, ImageUploader
end
