class Organization < ActiveRecord::Base

  has_many :publications
  has_many :users

  attr_accessible :name

  validates_presence_of :name
end
