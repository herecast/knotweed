# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  phone        :string(255)
#  email        :string(255)
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  contact_type :string(255)
#  address      :text
#

class Contact < ActiveRecord::Base
  attr_accessible :email, :name, :notes, :phone, :contact_type,
                  :organization_ids, :address

  has_and_belongs_to_many :organizations

  ADMINISTRATIVE = "Administrative"
  TECHNICAL = "Technical"
  CONTACT_TYPES = [ADMINISTRATIVE, TECHNICAL] 

  validates :contact_type, inclusion: { in: CONTACT_TYPES,
    message: "%{value} is not a valid contact type" }
end
