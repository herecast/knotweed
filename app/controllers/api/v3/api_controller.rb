module Api
  module V3
    class ApiController < ActionController::Base
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      # already handled by nginx
      #http_basic_authenticate_with name: Figaro.env.api_username, password: Figaro.env.api_password

      #token authentication for ember app
      before_action :authenticate_user_from_token!, :set_current_api_user,
        :set_current_thread_user

      # rescue CanCanCan authorization denied errors to use 403, not 500
      rescue_from CanCan::AccessDenied do |exception|
        render json: {}, status: :forbidden
      end

      protected

      def check_logged_in!
        unless current_user.present?
          render_401
        end
      end

      def render_401
        render json: { errors: 'You must be logged in.' }, status: 401
      end

      def set_current_api_user
        @current_api_user = current_user
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
        render json: {error: error.message}, status: :not_found
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
        !!@current_api_user.try(:skip_analytics?)
      end
    end
  end
end
