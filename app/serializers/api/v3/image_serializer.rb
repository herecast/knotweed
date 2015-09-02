module Api
  module V3
    class ImageSerializer < ActiveModel::Serializer
      attributes :caption, :credit, :url, :primary

      # attribute does not exist yet
      def primary
      end

      def url
        object.image.url
      end

    end
  end
end
