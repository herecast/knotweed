class Publication < ActiveRecord::Base
  
  has_many :issues
  belongs_to :organization
  has_many :contents, inverse_of: :contentsource, foreign_key: "contentsource_id"
  
  attr_accessible :name, :logo, :logo_cache, :remove_logo, :organization_id
  
  mount_uploader :logo, ImageUploader
end
