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
#  city                :string(255)
#  state               :string(255)
#  zip                 :string(255)
#

class BusinessLocation < ActiveRecord::Base
  extend Enumerize

  belongs_to :publication
  has_many :contents
  has_many :events, foreign_key: 'venue_id'
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by'
  belongs_to :updated_by, class_name: 'User', foreign_key: 'updated_by'

  attr_accessible :address, :email, :hours, :name, :publication_id, :phone, 
    :latitude, :longitude, :venue_url, :locate_include_name, :city, :state,
    :zip, :created_by, :updated_by, :status

  STATUS_CATEGORIES = [:approved, :new, :private]

  enumerize :status, in: STATUS_CATEGORIES

  geocoded_by :geocoding_address

  after_validation :geocode, if: ->(obj){ obj.address.present? and (obj.address_changed? or obj.name_changed? or obj.locate_include_name_changed?)}

  def select_option_label
    label = name || ''
    label += ' - ' if address.present? or city.present? or state.present? or zip.present?
    label += address if address.present?
    label += ' ' + city if city.present?
    label += ' ' + state if state.present?
    label += ' ' + zip if zip.present?
    label
  end

  def geocoding_address
    addr = ""
    if locate_include_name
      addr += name + " "
    end
    addr += address if address.present?
    addr += ' ' + city if city.present?
    addr += ' ' + state if state.present?
    addr += ' ' + zip if zip.present?

    addr
  end

  def full_address
    addr = ""
    addr += address + ',' if address.present?
    addr += ' ' + city if city.present?
    addr += ' ' + state if state.present?
    addr += ' ' + zip if zip.present?

    addr
  end
end
