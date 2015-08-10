module Api
  module V3
    class ApiController < ActionController::Base

      # already handled by nginx
      #http_basic_authenticate_with name: Figaro.env.api_username, password: Figaro.env.api_password

      before_filter :set_requesting_app_and_repository
      before_filter :set_current_api_user

      protected

      def check_logged_in!
        unless @current_api_user.present? or params[:current_user_id].present?
          render json: { errors: 'You must be logged in.' }, status: 401
        end
      end

      def set_current_api_user
        if params[:current_user_id].present?
          @current_api_user = User.find params[:current_user_id] 
        else
          @current_api_user = nil
        end
      end

      def set_requesting_app_and_repository
        @requesting_app = ConsumerApp.where(uri: params[:consumer_app_uri]).first_or_create if params[:consumer_app_uri].present?
        @repository = Repository.find_by_dsp_endpoint(params[:repository]) if params[:repository].present?
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

    end
  end
end
