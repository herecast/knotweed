# == Schema Information
#
# Table name: locations
#
#  id         :integer          not null, primary key
#  zip        :string(255)
#  city       :string(255)
#  state      :string(255)
#  county     :string(255)
#  lat        :string(255)
#  long       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Location < ActiveRecord::Base

  has_and_belongs_to_many :publications
  has_and_belongs_to_many :contents

  has_and_belongs_to_many :parents, class_name: "Location", foreign_key: :child_id, association_foreign_key: :parent_id
  has_and_belongs_to_many :children, class_name: "Location", foreign_key: :parent_id, association_foreign_key: :child_id
 
  attr_accessible :city, :county, :lat, :long, :state, :zip, :publication_ids

  default_scope order: :city

  def name
    "#{try(:city)} #{try(:state)}"
  end
end
