class Contact < ActiveRecord::Base
  attr_accessible :email, :name, :notes, :phone

  has_many :publications
end
