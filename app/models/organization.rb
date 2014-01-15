class Organization < ActiveRecord::Base

  has_and_belongs_to_many :contacts
  has_many :publications
  has_many :users
  has_many :parsers
  has_many :import_jobs
  has_many :locations, through: :publications

  attr_accessible :name, :org_type, :notes

  ORG_TYPE_OPTIONS = ["Publisher", "Business", "Ad Agency"]

  validates_presence_of :name
  validates :org_type, inclusion: { in: ORG_TYPE_OPTIONS }, allow_nil: true

  def org_type_enum
    ORG_TYPE_OPTIONS
  end


end
