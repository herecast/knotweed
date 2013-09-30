class Parameter < ActiveRecord::Base
  belongs_to :parser
  
  attr_accessible :name, :parser_id
  
  validates_presence_of :name
end
