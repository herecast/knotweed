module Api
  module V3
    class Users::PaymentsController < ApiController
      before_action :check_logged_in!

      def index
        authorize! :manage, User.find(params[:user_id])
        @payments = Payment.paid.for_user(params[:user_id]).by_period.limit(6)
        render json: @payments, each_serializer: PaymentsSerializer,
          context: { user_id: params[:user_id] }, root: :content_payments
      end

    end
  end
end
