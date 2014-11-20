# == Schema Information
#
# Table name: business_locations
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  address             :string(255)
#  phone               :string(255)
#  email               :string(255)
#  hours               :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  publication_id      :integer
#  latitude            :float
#  longitude           :float
#  venue_url           :string(255)
#  locate_include_name :boolean          default(FALSE)
#

class BusinessLocation < ActiveRecord::Base
  belongs_to :publication
  has_many :contents

  attr_accessible :address, :email, :hours, :name, :publication_id, :phone, 
    :latitude, :longitude, :venue_url, :locate_include_name

  geocoded_by :geocoding_address

  after_validation :geocode, if: ->(obj){ obj.address.present? and (obj.address_changed? or obj.name_changed? or obj.locate_include_name_changed?)}

  def select_option_label
    "#{name} - #{address}"
  end

  def geocoding_address
    addr = ""
    if locate_include_name
      addr += name + " "
    end
    addr += address
    addr
  end

end
