class BusinessLocation < ActiveRecord::Base
  belongs_to :organization

  attr_accessible :address, :email, :hours, :name, :organization_id, :phone
end
