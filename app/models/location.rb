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
#  is_region       :boolean          default(FALSE)
#  slug            :string
#

class Location < ActiveRecord::Base
  # defaults to 77, the current production ID for "Upper Valley" location
  REGION_LOCATION_ID = Figaro.env.has_key?(:region_location_id) ? Figaro.env.region_location_id : 77

  DEFAULT_LOCATION = Figaro.env.has_key?(:default_location) ? Figaro.env.default_location \
    : 'Upper Valley'

  # coordinates for the center of the upper valley
  DEFAULT_LOCATION_COORDS = [43.645, -72.243]


  validates :slug, uniqueness: true
  validates :state, length: {is: 2}, if: :state?

  has_many :organization_locations
  has_many :organizations, through: :organization_locations
  has_many :content_locations
  has_many :contents, through: :content_locations

  has_and_belongs_to_many :listservs

  has_many :users

  has_and_belongs_to_many :parents, class_name: 'Location', foreign_key: :child_id, association_foreign_key: :parent_id
  has_and_belongs_to_many :children, class_name: 'Location', foreign_key: :parent_id, association_foreign_key: :child_id

  scope :consumer_active, -> { where consumer_active: true }
  scope :not_upper_valley, -> { where "city != 'Upper Valley'" }

  scope :non_region, -> {
    where(is_region: false)
  }
  
  searchkick callbacks: :async, index_prefix: Figaro.env.stack_name,
    batch_size: 100, locations: ["location"]

  def search_data
    {
      id: id,
      location: {
        lat: lat,
        lon: long,
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
    "#{try(:city)} #{try(:state)}"
  end

  def coordinates=coords
    self.lat,self.long = coords
  end

  def coordinates
    return nil unless self.lat? && self.long?
    [self.lat.to_f,self.long.to_f]
  end

  alias_method :to_coordinates, :coordinates

  def coordinates?
    coordinates.present?
  end

  def latitude
    return nil unless self.lat?
    lat.to_f
  end

  def longitude
    return nil unless self.long?
    long.to_f
  end

  def self.with_distance latitude:, longitude:
    where('lat IS NOT NULL AND long IS NOT NULL')\
    .where("lat <> '' AND long <> ''")\
    .select(
      "*,
        #{sql_distance_calculation(latitude, longitude)} AS distance
      "
    )
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
    latitude, longitude = Geocoder::Calculations.extract_coordinates(point)
    where('lat IS NOT NULL AND long IS NOT NULL')\
    .where("lat <> '' AND long <> ''")\
    .where("#{sql_distance_calculation(latitude, longitude)} <= ?", radius)
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
    match = city_state.try(:strip).try(:match, '(.*)((\s|,)[a-zA-Z][a-zA-Z]$)')
    args = {}
    if match
      city,state,sep = match.captures
      state = state.strip.sub(',' , '')
      args[:state] = state
    else
      city = city_state
    end

    city = city.strip.sub(',', '') if city.present?
    args[:city] = city
    Location.where(args).first
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
            'location' => "#{lat},#{long}",
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

  private
  def self.sql_distance_calculation(latitude, longitude)
    "( 3959 * acos( cos( radians(#{sanitize(latitude)}::float8) ) *
            cos( radians( locations.lat::float8 ) ) * 
          cos( radians( locations.long::float8 ) - radians(#{sanitize(longitude)}::float8) ) +
          sin( radians(#{sanitize(latitude)}::float8) ) * 
          sin( radians( locations.lat::float8 ) ) )
        )"
  end
end
