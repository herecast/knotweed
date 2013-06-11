class Location < ActiveRecord::Base
  
  has_many :issues
  has_many :contents
  
  attr_accessible :city, :state, :zip
  
  
end
