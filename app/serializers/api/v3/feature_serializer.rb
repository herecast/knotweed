module Api
  module V3
    class FeatureSerializer < ActiveModel::Serializer
      attributes :name, :options

      def options
        JSON.parse(object.options) unless object.options.blank?
      end
    end
  end
end
