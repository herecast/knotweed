module Api
  module V3
    class BusinessFeedbacksController < ApiController
      before_action :check_logged_in!
      before_action :prevent_multiple_ratings, only: [:create]

      def create
        # created_by is automatically set by Auditable concern
        params[:feedback][:business_profile_id] = params[:id]

        @business_feedback = BusinessFeedback.new(feedback_params)
        if @business_feedback.save
          render json: @business_feedback, serializer: BusinessFeedbackSerializer,
            status: 201
        else
          render json: { errors: @business_feedback.errors.messages },
            status: :unprocessable_entity
        end
      end

      def update
        params[:feedback][:business_profile_id] = params[:id]

        @business_feedback = BusinessFeedback.find_by(created_by_id: current_user.id, business_profile_id: params[:id])
        if @business_feedback.update_attributes(feedback_params)
          render json: @business_feedback, serializer: BusinessFeedbackSerializer, status: :ok
        else
          render json: { errors: @business_feedback.errors.messages }, status: :unprocessable_entity
        end
      end

      private

        def prevent_multiple_ratings
          if BusinessFeedback.find_by(created_by_id: current_user.id, business_profile_id: params[:id]).present?
            render json: {}, status: :forbidden
          end
        end

        def feedback_params
          params.require(:feedback).permit(
            :business_profile_id,
            :satisfaction,
            :cleanliness,
            :price,
            :recommend
          )
        end

    end
  end
end
