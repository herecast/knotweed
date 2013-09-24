class Organization < ActiveRecord::Base

  has_many :publications
  has_many :users
  has_many :parsers
  has_many :import_jobs

  attr_accessible :name

  validates_presence_of :name
end
