module Api
  module V3
    class MarketCategorySerializer < ActiveModel::Serializer
      attributes :id, :name, :query, :category_image, :detail_page_banner,
        :featured, :trending, :count

      def count
        object.result_count
      end

      def category_image
        object.category_image.url if object.category_image.present?
      end

      def detail_page_banner
        object.detail_page_banner.url if object.detail_page_banner.present?
      end
    end
  end
end
