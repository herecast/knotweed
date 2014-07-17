# == Schema Information
#
# Table name: business_locations
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  organization_id :integer
#  address         :string(255)
#  phone           :string(255)
#  email           :string(255)
#  hours           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class BusinessLocation < ActiveRecord::Base
  belongs_to :organization

  attr_accessible :address, :email, :hours, :name, :organization_id, :phone
end
