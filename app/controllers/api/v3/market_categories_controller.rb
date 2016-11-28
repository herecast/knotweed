module Api
  module V3
    class MarketCategoriesController < ApiController
      def index
       # @market_categories = MarketCategory.all
      @market_categories = MarketCategory.order(updated_at: :desc)

       render json: @market_categories, arrayserializer: MarketCategorySerializer
      end

      def show
        @market_category = MarketCategory.find(params[:id])

        render json: @market_category, serializer: MarketCategorySerializer
      end
    end
  end
end
