module Api
  module V3
    class OrganizationSerializer < ActiveModel::Serializer

      attributes :id, :name, :can_publish_news

    end
  end
end
