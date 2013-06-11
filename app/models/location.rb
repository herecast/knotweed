class Location < ActiveRecord::Base
  
  has_many :issues
  
  attr_accessible :city, :state, :zip
  
  
end
