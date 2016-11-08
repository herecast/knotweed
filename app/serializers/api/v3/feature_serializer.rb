module Api
  module V3
    class FeatureSerializer < ActiveModel::Serializer
      attributes :name
    end
  end
end
