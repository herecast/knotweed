# == Schema Information
#
# Table name: locations
#
#  id                              :integer          not null, primary key
#  zip                             :string(255)
#  city                            :string(255)
#  state                           :string(255)
#  county                          :string(255)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  consumer_active                 :boolean          default(FALSE)
#  is_region                       :boolean          default(FALSE)
#  slug                            :string
#  latitude                        :float
#  longitude                       :float
#  default_location                :boolean          default(FALSE)
#  location_ids_within_five_miles  :integer          default([]), is an Array
#  location_ids_within_fifty_miles :integer          default([]), is an Array
#
# Indexes
#
#  index_locations_on_latitude_and_longitude  (latitude,longitude)
#

require 'geocoder/stores/active_record'

class Location < ActiveRecord::Base
  include Geocoder::Store::ActiveRecord #include query helpers

  def self.geocoder_options
    {
      latitude: :latitude,
      longitude: :longitude
    }
  end

  def self.default_location
    find_by_default_location(true)
  end

  # coordinates for the center of the upper valley
  DEFAULT_LOCATION_COORDS = [43.645, -72.243]


  validates :slug, uniqueness: true
  validates :state, length: {is: 2}, if: :state?

  has_many :organization_locations
  has_many :organizations, through: :organization_locations
  has_many :contents

  has_and_belongs_to_many :listservs

  has_many :users

  has_and_belongs_to_many :parents, class_name: 'Location', foreign_key: :child_id, association_foreign_key: :parent_id
  has_and_belongs_to_many :children, class_name: 'Location', foreign_key: :parent_id, association_foreign_key: :child_id

  scope :consumer_active, -> { where consumer_active: true }
  scope :not_upper_valley, -> { where "city != 'Upper Valley'" }

  scope :non_region, -> {
    where(is_region: false)
  }

  scope :with_slug, -> {
    where("slug IS NOT NULL AND slug <> ''")
  }

  searchkick callbacks: :async,
    index_prefix: Figaro.env.stack_name,
    batch_size: 1000,
    locations: ["location"],
    match: :word_start,
    searchable: [:city, :state, :zip]

  def search_data
    {
      id: id,
      location: {
        lat: latitude,
        lon: longitude,
      },
      city: city,
      state: state,
      zip: zip
    }
  end

  def parent_city
    # Currently locations support multiple parents.
    # But we aren't using that in the data currently.
    # So this will return the first non-region it finds in the relationship.
    parent = parents.consumer_active.non_region.first
    return parent.try(:parent_city) || parent
  end

  def should_index?
    consumer_active?
  end

  def name
    "#{try(:city)}, #{try(:state)}"
  end

  def pretty_name
    unless city.nil? || state.nil?
      "#{city}, #{state}"
    end
  end

  def coordinates=coords
    self.latitude,self.longitude = coords
  end

  def coordinates
    [latitude, longitude].compact
  end

  alias_method :to_coordinates, :coordinates

  def coordinates?
    coordinates.present?
  end

  def self.with_distance latitude:, longitude:
    select("*, #{distance_from_sql([latitude, longitude])} as distance")
  end

  def self.nearest_to_coords latitude:, longitude:
    with_distance(
      latitude: latitude,
      longitude: longitude
    )\
    .order('distance ASC')
  end

  def self.nearest_to_ip ip
    result = Geocoder.search(ip).first

    if result
      nearest_to_coords latitude: result.latitude, longitude: result.longitude
    else
      []
    end
  end

  def self.within_radius_of(point, radius)
    geocoded.near(point, radius)
  end

  def self.find_by_slug_or_id identifier
    if identifier.to_s =~ /^\d+$/
      find(identifier)
    else
      find_by(slug: identifier)
    end
  end

  #though the HABTM relationship allows for many listservs, in reality
  #each location will only have one listserv
  def listserv
    self.listservs.first
  end

  # queries ElasticSearch index and returns the closest num locations
  def closest(num=8)
    opts =  {
      order: {
          _geo_distance: {
            'location' => "#{latitude},#{longitude}",
            'order' => 'asc',
            'unit' => 'mi'
        }
      },
      limit: num,
      where: {
          id: { not: self.id }
      }
    }
    Location.search('*', opts).results
  end

  def city=c
    write_attribute :city, c
    build_slug
    c
  end

  def state=s
    write_attribute :state, s
    build_slug
    s
  end

  def build_slug
    self.slug= "#{city} #{state}".parameterize
  end
end
