module Api
  module V3
    class ApiController < ActionController::Base

      # already handled by nginx
      #http_basic_authenticate_with name: Figaro.env.api_username, password: Figaro.env.api_password

      #token authentication for ember app
      before_filter :authenticate_user_from_token!

      before_filter :set_requesting_app_and_repository
      before_filter :set_current_api_user

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
        @requesting_app = ConsumerApp.where(uri: params[:consumer_app_uri]).first_or_create if params[:consumer_app_uri].present?
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
    end
  end
end
