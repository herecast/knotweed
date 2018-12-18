# frozen_string_literal: true

module Api
  module V3
    class SubscriptionsController < ApiController
      before_action :get_resource, only: %i[show update confirm]
      before_action :check_logged_in!, only: [:index]

      def index
        @subscriptions = Subscription.where(user_id: current_user.id)\
                                     .where(unsubscribed_at: nil).page(params[:page]).per(params[:per_page] || 25)

        render json: @subscriptions,
               each_serializer: SubscriptionSerializer,
               meta: meta_pagination_for(@subscriptions)
      end

      def show
        render json: @subscription, serializer: SubscriptionSerializer
      end

      def create
        if params[:subscription][:listserv_id].present?
          user = find_user
          listserv = Listserv.find(params[:subscription][:listserv_id])
          if user.confirmed?
            @subscription = SubscribeToListservSilently.call(listserv, user, request.remote_ip)
          elsif subscribed_from_registration?
            @subscription = Subscription.create!(subscription_params)
          else
            @subscription = SubscribeToListserv.call(listserv, email: params[:subscription][:email])
          end
          render json: @subscription, serializer: SubscriptionSerializer, status: 201
        else
          render json: { errors: 'listserv_id cant be blank' }, status: 422
        end
      end

      def update
        if @subscription.update subscription_params
          render json: {}, status: :no_content
        else
          render json: { errors: @subscription.errors }, status: 422
        end
      end

      def confirm
        ConfirmSubscription.call(@subscription, request.remote_ip)

        render json: {}, status: :no_content
      end

      def destroy
        if params[:key].present?
          get_resource
          UnsubscribeSubscription.call(@subscription)
        elsif params[:email].present? && params[:listserv_id].present?
          encoded_email = CGI.unescape(params[:email].to_s)
          listserv = Listserv.find_by(id: params[:listserv_id])
          if encoded_email.present? && listserv.present?
            @subscription = Subscription.find_by(
              email: Base64.decode64(encoded_email),
              listserv_id: listserv.id
            )
            UnsubscribeSubscription.call(@subscription) if @subscription.present?
          end
        else
          render json: { errors: 'Invalid parameters' }, status: :unprocessable_entity
          return
        end
        render json: {}, status: :no_content
      end

      def unsubscribe_from_mailchimp
        subscription = find_subscription
        subscription.unsubscribed_at ||= Time.zone.now
        subscription.mc_unsubscribed_at = Time.zone.now
        subscription.save!

        render json: subscription, serializer: SubscriptionSerializer
      end

      def verify_mc_webhook
        render json: {}, status: :ok
      end

      protected

      def get_resource
        @subscription = Subscription.find_by(key: params[:key])
        render json: {}, status: :not_found unless @subscription
      end

      def subscription_params
        params.require(:subscription).permit(:email_type, :name, :user_id,
                                             :listserv_id, :source, :email,
                                             :confirmed_at)
      end

      def user_from_mailchimp
        email = params['data']['email']
        User.find_by(email: email)
      end

      def listserv_from_mailchimp
        mc_list_id = params['data']['list_id']
        Listserv.where(mc_list_id: mc_list_id).try(:first)
      end

      def find_subscription
        Subscription.where('listserv_id = ? AND email = ?',
                           listserv_from_mailchimp.id, params['data']['email'])
                    .try(:first)
      end

      def find_user
        User.find_by(email: params[:subscription][:email])
      end

      def subscribed_from_registration?
        params[:subscription][:subscribed_from_registration]
      end
    end
  end
end
