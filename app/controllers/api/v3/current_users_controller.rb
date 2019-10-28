# frozen_string_literal: true

module Api
  module V3
    class CurrentUsersController < ApiController
      before_action :check_logged_in!

      def show
        render json: current_user, serializer: CurrentUserSerializer, status: :ok
      end

      def update
        authorize! :update, current_user
        if current_user.update_attributes(current_user_params)
          render json: current_user, serializer: CurrentUserSerializer, status: 200
        else
          render json: error_packet, status: 422
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
            :feed_card_size,
            :background_image,
            :description,
            :website,
            :handle,
            :email_is_public,
            :avatar,
            :background_image,
            :description,
            :website,
            :phone
          ).tap do |attrs|
            if params[:current_user][:location_id].present?
              location = Location.find_by_slug_or_id(params[:current_user][:location_id])
              attrs[:location_id] = location.id
            end
          end
        end

        def error_packet
          { error: 'Update failed', messages: current_user.errors.full_messages }
        end

    end
  end
end