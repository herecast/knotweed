# frozen_string_literal: true

module Api
  module V3
    class ApiController < ActionController::Base
      protect_from_forgery with: :exception, unless: -> { request.format.json? }
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      # token authentication for ember app
      before_action :authenticate_user_from_token!, :set_current_thread_user

      # rescue CanCanCan authorization denied errors to use 403, not 500
      rescue_from CanCan::AccessDenied do |_exception|
        render json: {}, status: :forbidden
      end

      protected

      def check_logged_in!
        unless current_user.present?
          render json: { errors: 'You must be logged in.' }, status: 401
        end
      end

      def authenticate_user_from_token!
        authenticate_with_http_token do |token, options|
          user_email = options[:email].presence
          user = user_email && User.find_by_email(user_email)
          if user && Devise.secure_compare(user.authentication_token, token)
            sign_in user, store: false
          end
        end
      end

      def set_current_thread_user
        User.current = current_user
      end

      def record_not_found(error)
        render json: { error: error.message }, status: :not_found
      end

      def meta_pagination_for(scope)
        {
          total_count: scope.total_count,
          page: scope.current_page,
          per_page: scope.size,
          page_count: scope.total_pages
        }
      end

      def analytics_blocked?
        !!current_user.try(:skip_analytics?)
      end
    end
  end
end
