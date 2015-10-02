module Api
  module V1
    class ApiController < ActionController::Base

      # already handled by nginx
      #http_basic_authenticate_with name: Figaro.env.api_username, password: Figaro.env.api_password

      before_filter :set_requesting_app, :set_current_thread_user,
        :set_thread_consumer_app_nil

      protected

      def set_current_thread_user
        User.current = current_user
      end

      # I realize this is a little counterintuitive, but here's why it exists:
      # the reverse publish emails needed to have a separate URL for Ux2. To determine that,
      # we're relying on having Thread.current[:consumer_app] set -- that only 
      # needs to be set for UX2. So in order to make the reverse publish email logic
      # work properly, we need to ensure that's nil here.
      def set_thread_consumer_app_nil
        ConsumerApp.current = nil
      end

      def set_requesting_app
        @requesting_app = ConsumerApp.where(uri: params[:consumer_app_uri]).first_or_create if params[:consumer_app_uri].present?
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
