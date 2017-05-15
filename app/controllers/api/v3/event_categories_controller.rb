module Api
  module V3
    class EventCategoriesController < ApiController

      def index
        @event_categories = EventCategory.alphabetical
        render json: @event_categories, each_serializer: EventCategorySerializer
      end
    end
  end
end