# frozen_string_literal: true

module Api
  module V3
    class Users::SessionsController < ApiController
      before_action :check_logged_in!, only: %i[destroy]

      # NOTE: ember app hits this with a post request, should ultimately
      # be changed to a DELETE request
      def destroy
        user = current_user
        sign_out current_user
        user.reset_authentication_token
        res = if user.save
                :ok
              else
                :unprocessable_entity
              end
        reset_session
        render json: {}, status: res
      end
    end
  end
end
