class Contact < ActiveRecord::Base
  attr_accessible :email, :name, :notes, :phone, :contact_type

  has_and_belongs_to_many :publications

  ADMINISTRATIVE = "Administrative"
  TECHNICAL = "Technical"
  CONTACT_TYPES = [ADMINISTRATIVE, TECHNICAL] 

  validates :contact_type, inclusion: { in: CONTACT_TYPES,
    message: "%{value} is not a valid contact type" }
end
