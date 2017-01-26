module Api
  module V3
    class TempUserCapturesController < ApiController
      def create
        @temp_user = TempUserCapture.new(temp_user_params)

        if @temp_user.save
          render json: @emp_user, status: 201
        elsif @temp_user.new_user?
          render json: { errors: ["User already has an account for given email"] }
        else
          render json: { errors: ["User info could not be saved"] }
        end
      end

      private

      def temp_user_params
        params.require(:temp_user_capture).permit(:name, :email)
      end
    end
  end
end
