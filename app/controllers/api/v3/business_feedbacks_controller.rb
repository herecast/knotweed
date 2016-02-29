module Api
  module V3
    class BusinessFeedbacksController < ApiController
      before_filter :check_logged_in!

      def create
        # created_by is automatically set by Auditable concern
        params[:feedback][:business_profile_id] = params[:id]
        @business_feedback = BusinessFeedback.new(params[:feedback])
        if @business_feedback.save
          render json: @business_feedback, serializer: BusinessFeedbackSerializer,
            status: 201
        else
          render json: { errors: @business_feedback.errors.messages },
            status: :unprocessable_entity
        end
      end
    end
  end
end
