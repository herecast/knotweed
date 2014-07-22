class PublicationSerializer < ActiveModel::Serializer

  attributes :id, :name, :logo, :header, :links, :latest_presentation

  self.root = false
  has_many :business_locations

  def latest_presentation
    object.latest_presentation
  end
end
