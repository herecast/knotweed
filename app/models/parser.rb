# == Schema Information
#
# Table name: parsers
#
#  id              :integer          not null, primary key
#  filename        :string(255)
#  organization_id :integer
#  name            :string(255)
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Parser < ActiveRecord::Base
  belongs_to :organization
  has_many :parameters
  has_many :import_jobs
  
  attr_accessible :filename, :organization_id, :name, :description, :parameters_attributes,
                  :parameter
  
  validates :filename, uniqueness: true

  accepts_nested_attributes_for :parameters, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true
  
end
