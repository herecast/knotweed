# frozen_string_literal: true

module Api
  module V3
    class UsersController < ApiController
      include EmailTemplateHelper
      before_action :check_logged_in!, only: %i[show update]

      def show
        render json: current_user, serializer: UserSerializer,
               root: 'current_user', status: 200,
               context: { current_ability: current_ability }
      end

      def update
        authorize! :update, current_user
        if current_user.update_attributes(current_user_params)
          render json: current_user, serializer: UserSerializer, root: 'current_user', status: 200,
                 context: { current_ability: current_ability }
        else
          render json: { error: 'Current User update failed', messages: current_user.errors.full_messages }, status: 422
        end
      end

      # used for the `verify` endpoint that queries for the existence
      # of users by email
      def index
        if User.exists?(['lower(email) = ?', params[:email].downcase])
          render json: {}, status: :ok
        else
          render json: {}, status: :not_found
        end
      end

      private

      def current_user_params
        params.require(:current_user).permit(
          :name,
          :email,
          :public_id,
          :location_confirmed,
          :password,
          :password_confirmation,
          :has_had_bookmarks,
          :feed_card_size
        ).tap do |attrs|
          if params[:current_user][:location_id].present?
            location = Location.find_by_slug_or_id(params[:current_user][:location_id])
            attrs[:location_id] = location.id
          end
          attrs[:avatar] = params[:current_user][:image] if params[:current_user][:image].present?
        end
      end
    end
  end
end
