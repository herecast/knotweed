module Api
  module V2
    class BusinessLocationSerializer < ActiveModel::Serializer

      attributes :id, :name, :address, :city, :state, :zip

    end
  end
end
