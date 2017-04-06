module Api
  module V3
    class ImageSerializer < ActiveModel::Serializer
      attributes :caption, :credit, :url, :primary, :id, :width, :height, :file_extension
      attributes :position

      def primary
        object.primary
      end

      def url
        object.image.url
      end
    end
  end
end
