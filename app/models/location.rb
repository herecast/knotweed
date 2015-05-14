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

  has_and_belongs_to_many :publications
  has_and_belongs_to_many :listservs
  has_and_belongs_to_many :contents

  has_and_belongs_to_many :parents, class_name: "Location", foreign_key: :child_id, association_foreign_key: :parent_id
  has_and_belongs_to_many :children, class_name: "Location", foreign_key: :parent_id, association_foreign_key: :child_id
 
  attr_accessible :city, :county, :lat, :long, :state, :zip, :publication_ids, :consumer_active

  default_scope order: :city

  def name
    "#{try(:city)} #{try(:state)}"
  end

  def self.get_ids_from_location_strings(loc_array)
    location_ids = []
    # get the ids of all the locations
    loc_array.each do |location_string|
      city_state = location_string.split(",")
      if city_state.present?
        if city_state[1].present?
          location = Location.where(city: city_state[0], state: city_state[1]).first
        else
          location = Location.where(city: city_state[0]).first
        end
        location_ids.push(location.id)
      end
    end
    location_ids
  end

end
