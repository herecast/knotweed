class Parser < ActiveRecord::Base
  belongs_to :organization
  has_many :parameters
  has_many :import_jobs
  
  attr_accessible :filename, :organization_id, :name, :description, :parameters_attributes,
                  :parameter
  
  validates :filename, uniqueness: true

  accepts_nested_attributes_for :parameters, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true
  
end
