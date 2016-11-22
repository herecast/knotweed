module Api
  module V3
    class MarketCategorySerializer < ActiveModel::Serializer
      attributes :id, :name, :query, :category_image, :detail_page_banner,
        :featured, :trending, :count

      def count
        object.result_count
      end
    end
  end
end
