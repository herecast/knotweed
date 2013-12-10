class Location < ActiveRecord::Base
  
  has_many :issues
  has_many :contents

  belongs_to :parent, :class_name => "Location"
  has_many :aliases, :class_name => "Location", :foreign_key => "parent_id"
  
  attr_accessible :city, :state, :zip, :country, :link_name, :link_name_full, :status,
                  :region_id, :parent_id, :usgs_id
  
  validates_presence_of :city

  default_scope where("status = 1 AND (region_id=0 or region_id=1)")
  scope :top_level, where("parent_id is NULL")

  STATUS_GOOD = 1
  STATUS_REVIEW = 2
  
  # label method for rails_admin
  def name
    "#{city}, #{state} #{zip}"
  end

  # this method is for matching location strings
  # from parsers into our locations database
  def self.find_or_create_from_match_string(query_string)
    match = false
    link_name = query_string.upcase.gsub(",", "").gsub(".", "").gsub("_", " ").gsub(/ {2,}/, " ")

    # first try to match just straight to the "city" entry
    query = Location.where("UPPER(city) = ?", query_string.upcase)
    query = Location.where("link_name = ?", link_name) if query.empty?
    query = Location.where("link_name_full = ?", link_name) if query.empty?

    if query.empty?
      # if nothing found, create new location record with status: REVIEW
      match = Location.create(city: query_string, link_name: link_name, status: STATUS_REVIEW)
    # might want to add logic in the future in the case where
    # query.length > 1...not sure.
    else query.length == 1
      match = query.first
      # if the match has a parent, return that instead
      match = match.parent if match.parent.present?
    end

    return match
  end
  
  
end
