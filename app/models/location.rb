class Location < ActiveRecord::Base
  
  has_many :issues
  has_many :contents
  
  attr_accessible :city, :state, :zip
  
  validates_presence_of :city
  
  # label method for rails_admin
  def name
    "#{city}, #{state} #{zip}"
  end
  
  
end
