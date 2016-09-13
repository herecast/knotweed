module Api
  module V3
    class SubscriptionsController < ApiController
      before_action :get_resource, only: [:show, :update, :confirm, :unsubscribe]
      before_action :check_logged_in!, only:  [:index]

      def index
        @subscriptions = Subscription.where(user_id: current_user.id)\
                          .page(params[:page]).per(params[:per_page] || 25)

        render json: @subscriptions,
          each_serializer: SubscriptionSerializer,
          meta: meta_pagination_for(@subscriptions)
      end

      def show
        render json: @subscription, serializer: SubscriptionSerializer
      end

      def update
        if @subscription.update subscription_params
          render json: {}, status: :ok
        else
          render json: {errors: @subscription.errors}, status: 422
        end
      end

      def confirm
        ConfirmSubscription.call(@subscription, request.remote_ip)

        render json: {}, status: :ok
      end

      def unsubscribe
        UnsubscribeSubscription.call(@subscription)

        render json: {}, status: :ok
      end

      protected
      def get_resource
        @subscription = Subscription.find_by(key: params[:key])
        unless @subscription
          head status: :not_found
        end
      end

      def subscription_params
        params.require(:subscription).permit(:email_type, :name)
      end
    end
  end
end
