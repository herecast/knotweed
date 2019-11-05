# frozen_string_literal: true

module Api
  module V3
    class UsersController < ApiController

      # used for the `verify` endpoint that queries for the existence
      # of users by email
      def index
        if User.exists?(['lower(email) = ?', params[:email].downcase])
          render json: {}, status: :ok
        else
          render json: {}, status: :not_found
        end
      end

    end
  end
end
