require 'subtext_tracker'

module Api
  module V3
    class ApiController < ActionController::Base

      # already handled by nginx
      #http_basic_authenticate_with name: Figaro.env.api_username, password: Figaro.env.api_password

      #token authentication for ember app
      before_filter :authenticate_user_from_token!

      before_filter :set_requesting_app_and_repository, :set_current_api_user,
        :set_current_thread_user, :init_mixpanel

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
        @repository = @requesting_app.repository if @requesting_app.present?
      end

      # generic method that, if requesting app is present, updates
      # active record relation having queried for objects that belong to
      # that consumer app
      #
      # only works on objects that have a habtm relationship with consumer apps
      # (e.g. wufooforms and messages)
      def filter_active_record_relation_for_consumer_app(relation)
        if @requesting_app.present? and relation.present?
          relation.select { |r| r.consumer_app_ids.include? @requesting_app.id }
        else
          relation
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

      def init_mixpanel
        @tracker ||= SubtextTracker.new(Figaro.env.mixpanel_api_token)
        @mixpanel_distinct_id = current_user.try(:id) || request.headers['Mixpanel-Distinct-Id']
      end

    end
  end
end
