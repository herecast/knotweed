# == Schema Information
#
# Table name: parameters
#
#  id         :integer          not null, primary key
#  parser_id  :integer
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Parameter < ActiveRecord::Base
  belongs_to :parser
  
  validates_presence_of :name
end
