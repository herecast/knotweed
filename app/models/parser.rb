class Parser < ActiveRecord::Base
  belongs_to :organization
  has_many :parameters
  has_many :import_jobs
  
  attr_accessible :filename, :organization_id, :name, :description
  
  validates :filename, uniqueness: true
  
end
