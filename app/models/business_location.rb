# == Schema Information
#
# Table name: business_locations
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  address             :string(255)
#  phone               :string(255)
#  email               :string(255)
#  hours               :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#  latitude            :float
#  longitude           :float
#  venue_url           :string(255)
#  locate_include_name :boolean          default(FALSE)
#  city                :string(255)
#  state               :string(255)
#  zip                 :string(255)
#  status              :string(255)
#  created_by          :integer
#  updated_by          :integer
#  service_radius      :decimal(10, )
#
# Indexes
#
#  idx_16441_index_business_locations_on_city        (city)
#  idx_16441_index_business_locations_on_created_by  (created_by)
#  idx_16441_index_business_locations_on_name        (name)
#

class BusinessLocation < ActiveRecord::Base
  extend Enumerize
  include Auditable

  searchkick callbacks: :async, batch_size: 5000, index_prefix: Figaro.env.searchkick_index_prefix,
    match: :word_start, searchable: [:name, :city, :state]

  def search_data
    {
      name: name,
      city: city,
      state: state,
      created_by: created_by.try(:id),
      status: status
    }
  end

  belongs_to :organization
  has_many :events, foreign_key: 'venue_id'

  has_one :business_profile

  serialize :hours, Array

  validate :state_length_if_present

  STATUS_CATEGORIES = [:approved, :new, :private]

  enumerize :status, in: STATUS_CATEGORIES

  geocoded_by :geocoding_address

  after_commit :reindex_associations_async
  def reindex_associations_async
    business_profile.reindex_async if business_profile.present?
    if events.present?
      events.each do |e|
        e.event_instances.each do |ei|
          ei.reindex_async
        end
      end
    end
  end

  after_validation :geocode, if: ->(obj){ obj.address.present? and (obj.address_changed? or obj.name_changed? or obj.locate_include_name_changed?)}

  def select_option_label
    label = name || ''
    label += ' - ' if address.present? or city.present? or state.present? or zip.present?
    label += address if address.present?
    label += ' ' + city if city.present?
    label += ', ' + state if state.present?
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
    addr += ', ' + state if state.present?
    addr += ' ' + zip if zip.present?

    addr
  end

  def coordinates
    [latitude, longitude]
  end

  def coordinates=coords
    self.latitude, self.longitude = coords
  end

  def location
    matching = location_matching_city_state
    return matching if matching

    nearest = nearest_location_within_10_miles
    return nearest.try(:parent_city) || nearest
  end

  def location_matching_city_state
    Location.where(
      "lower(city) = lower(:city) AND lower(state) = lower(:state)",
      city: city,
      state: state
    ).first
  end

  def nearest_location_within_10_miles
    Location.within_radius_of(coordinates, 10).with_distance(
      latitude: latitude,
      longitude: longitude
    ).order('distance ASC').first
  end

  private

    def state_length_if_present
      if state.present? && state.length != 2
        errors.add(:state, 'State must be two-letter abbreviation')
      end
    end

end
