# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  zip             :string(255)
#  city            :string(255)
#  state           :string(255)
#  county          :string(255)
#  lat             :string(255)
#  long            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  consumer_active :boolean          default(FALSE)
#

class Location < ActiveRecord::Base
  # defaults to 77, the current production ID for "Upper Valley" location
  REGION_LOCATION_ID = Figaro.env.has_key?(:region_location_id) ? Figaro.env.region_location_id : 77

  DEFAULT_LOCATION = Figaro.env.has_key?(:default_location) ? Figaro.env.default_location \
    : 'Upper Valley'

  has_and_belongs_to_many :publications
  has_and_belongs_to_many :listservs
  has_and_belongs_to_many :contents

  has_many :users

  has_and_belongs_to_many :parents, class_name: 'Location', foreign_key: :child_id, association_foreign_key: :parent_id
  has_and_belongs_to_many :children, class_name: 'Location', foreign_key: :parent_id, association_foreign_key: :child_id
 
  attr_accessible :city, :county, :lat, :long, :state, :zip, :publication_ids, :consumer_active

  default_scope order: :city

  scope :consumer_active, where(consumer_active: true)

  def name
    "#{try(:city)} #{try(:state)}"
  end

  def self.get_ids_from_location_strings(loc_array)
    location_ids = []
    # get the ids of all the locations
    loc_array.each do |location_string|
      # city_state = location_string.split(",")
      # if city_state.present?
      #   if city_state[1].present?
      #     location = Location.where(city: city_state[0].strip, state: city_state[1].strip).first
      #   else
      #     location = Location.where(city: city_state[0].strip).first
      #   end
      location = find_by_city_state(location_string)
      location_ids |= [location.id] if location.present?
#      end
    end
    location_ids
  end

  def self.find_by_city_state(city_state)
    location = nil
    cs = city_state.split(',')
    if cs.present?
      if cs[1].present?
        location = Location.where(city: cs[0].strip, state: cs[1].strip).first
      else
        location = Location.where(city: cs[0].strip).first
      end
    end
    location
  end

  #though the HABTM relationship allows for many listservs, in reality
  #each location will only have one listserv
  def listserv
    self.listservs.first
  end
end
