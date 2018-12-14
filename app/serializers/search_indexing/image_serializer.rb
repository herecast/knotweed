# frozen_string_literal: true

module SearchIndexing
  class ImageSerializer < ActiveModel::Serializer
    attributes :id, :image_url, :primary, :width, :height, :file_extension, :position, :created_at

    def image_url
      object.image.url
    end
  end
end
