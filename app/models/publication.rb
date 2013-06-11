class Publication < ActiveRecord::Base
  
  has_many :issues
  
  attr_accessible :name
end
