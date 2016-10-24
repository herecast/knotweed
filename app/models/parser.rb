# == Schema Information
#
# Table name: parsers
#
#  id              :integer          not null, primary key
#  filename        :string(255)
#  name            :string(255)
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Parser < ActiveRecord::Base
  has_many :parameters
  has_many :import_jobs
  
  validates :filename, uniqueness: true

  accepts_nested_attributes_for :parameters, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true
  
end
