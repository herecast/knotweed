class Organization < ActiveRecord::Base

  has_many :publications
  has_many :users
  has_many :parsers
  has_many :import_jobs

  attr_accessible :name, :type, :notes

  TYPE_OPTIONS = ["Publisher"]

  validates_presence_of :name
  validates :type, inclusion: { in: TYPE_OPTIONS }, allow_nil: true

  def type_enum
    TYPE_OPTIONS
  end


end
