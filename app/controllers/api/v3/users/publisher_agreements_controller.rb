module Api
  module V3
    class Users::PublisherAgreementsController < ApiController

      def create
        authorize! :update, current_user
        user = User.find(params[:user_id])
        user.update_attributes(publisher_agreement_params)
        PublishersMailer.publisher_agreement_confirmation(user).deliver_later
        render json: user,
          serializer: UserSerializer,
          root: 'current_user', 
          context: { current_ability: current_ability },
          status: 200
      end

      private

        def publisher_agreement_params
          {
            publisher_agreement_confirmed: true,
            publisher_agreement_confirmed_at: Time.current,
            publisher_agreement_version: 'october-2019'
          }
        end

    end
  end
end