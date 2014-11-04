# == Schema Information
#
# Table name: business_locations
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  address        :string(255)
#  phone          :string(255)
#  email          :string(255)
#  hours          :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  publication_id :integer
#  latitude       :float
#  longitude      :float
#

class BusinessLocation < ActiveRecord::Base
  belongs_to :publication
  has_many :contents

  attr_accessible :address, :email, :hours, :name, :publication_id, :phone, 
    :latitude, :longitude, :venue_url

  geocoded_by :address

  after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed? }

  def select_option_label
    "#{name} - #{address}"
  end

end
