# frozen_string_literal: true

module Api
  module V3
    class CurrentUsers::PasswordsController < ApiController
      before_action :check_logged_in!

      def show
        if current_user.valid_password?(params[:password])
          render json: {}, status: :ok
        else
          render json: {}, status: :not_found
        end
      end
    end
  end
end