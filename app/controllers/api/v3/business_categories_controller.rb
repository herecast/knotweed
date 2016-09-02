module Api
  module V3
    class BusinessCategoriesController < ApiController

      def index
        expires_in 1.hours, :public => true
        # display all root business categories since children are included in the
        # serializer
        @business_categories = BusinessCategory.all
        render json: @business_categories, each_serializer: BusinessCategorySerializer
      end

    end
  end
end
