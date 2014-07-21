class PublicationSerializer < ActiveModel::Serializer

  attributes :id, :name, :logo, :header, :links

  self.root = false
  has_many :business_locations
end
