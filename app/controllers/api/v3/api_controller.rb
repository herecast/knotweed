require 'subtext_tracker'

module Api
  module V3
    class ApiController < ActionController::Base
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      # already handled by nginx
      #http_basic_authenticate_with name: Figaro.env.api_username, password: Figaro.env.api_password

      #token authentication for ember app
      before_filter :authenticate_user_from_token!

      before_filter :set_requesting_app_and_repository, :set_current_api_user,
        :set_current_thread_user, :init_mixpanel

      # rescue CanCanCan authorization denied errors to use 403, not 500
      rescue_from CanCan::AccessDenied do |exception|
        render nothing: true, status: :forbidden
      end

      protected

      def check_logged_in!
        unless current_user.present?
          render json: { errors: 'You must be logged in.' }, status: 401
        end
      end

      def set_current_api_user
        @current_api_user = current_user
      end

      def set_requesting_app_and_repository
        if request.headers['Consumer-App-Uri'].present?
          @requesting_app = ConsumerApp.find_by_uri(request.headers['Consumer-App-Uri'])
        elsif params[:consumer_app_uri].present?
          @requesting_app = ConsumerApp.find_by_uri(params[:consumer_app_uri])
        end
        ConsumerApp.current = @requesting_app if @requesting_app.present?
        @repository = @requesting_app.repository if @requesting_app.present?
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

      def init_mixpanel
        @tracker ||= SubtextTracker.new(Figaro.env.mixpanel_api_token)
        @mixpanel_distinct_id = current_user.try(:id) || request.headers['Mixpanel-Distinct-Id']
      end

      def record_not_found
        head :not_found
      end

      def meta_pagination_for(scope)
        {
          total_count: scope.total_count,
          page: scope.current_page,
          per_page: scope.size,
          page_count: scope.total_pages
        }
      end

      def excluded_user_agents
        ["Prerender"]
      end

      def request_user_agent
        request.env['HTTP_USER_AGENT']
      end

      def exclude_from_impressions?
        if request_user_agent.present?
          excluded_user_agents.any? { |agent| request_user_agent[agent] }
        end
      end
    end
  end
end
