module Api
  module V3
    class BusinessCategoriesController < ApiController

      def index
        # display all root business categories since children are included in the
        # serializer
        @business_categories = BusinessCategory.all
        render json: @business_categories, each_serializer: BusinessCategorySerializer
      end

    end
  end
end