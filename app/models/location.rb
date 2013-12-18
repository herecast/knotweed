class Location < ActiveRecord::Base

  has_and_belongs_to_many :publications

  attr_accessible :city, :county, :lat, :long, :state, :zip, :publication_ids

  default_scope order: :city

  def name
    "#{try(:city)} #{try(:state)}"
  end
end
