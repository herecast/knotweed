# == Schema Information
#
# Table name: import_locations
#
#  id             :integer          not null, primary key
#  parent_id      :integer          default(0)
#  region_id      :integer          default(0)
#  city           :string(255)
#  state          :string(255)
#  zip            :string(255)
#  country        :string(128)
#  link_name      :string(255)
#  link_name_full :string(255)
#  status         :integer          default(0)
#  usgs_id        :string(128)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  idx_16657_city            (city)
#  idx_16657_link_name       (link_name)
#  idx_16657_link_name_full  (link_name_full)
#  idx_16657_state           (state)
#  idx_16657_status          (status)
#  idx_16657_usgs_id         (usgs_id)
#

class ImportLocation < ActiveRecord::Base
  
  has_many :issues
  has_many :contents

  belongs_to :parent, :class_name => "ImportLocation"
  has_many :aliases, :class_name => "ImportLocation", :foreign_key => "parent_id"
  
  validates_presence_of :city

  default_scope { where("status = 1 AND (region_id=0 or region_id=1)") }

  STATUS_GOOD = 1
  STATUS_REVIEW = 2
  
  # this method is for matching location strings
  # from parsers into our locations database
  def self.find_or_create_from_match_string(query_string)
    match = false
    link_name = query_string.upcase.gsub(",", "").gsub(".", "").gsub("_", " ").gsub(/ {2,}/, " ")

    # first try to match just straight to the "city" entry
    query = ImportLocation.where("UPPER(city) = ?", query_string.upcase)
    query = ImportLocation.where("link_name = ?", link_name) if query.empty?
    query = ImportLocation.where("link_name_full = ?", link_name) if query.empty?

    if query.empty?
      # if nothing found, create new location record with status: REVIEW
      match = ImportLocation.create(city: query_string, link_name: link_name, status: STATUS_REVIEW)
    # might want to add logic in the future in the case where
    # query.length > 1...not sure.
    else #query.length == 1
      match = query.first
      # if the match has a parent, return that instead
      match = match.parent if match.parent.present?
    end

    return match
  end

  # returns name for display in select boxes, other UI place
  def name
    "#{city}, #{state} #{zip}"
  end
  
end
