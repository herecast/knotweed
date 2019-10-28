# frozen_string_literal: true

module Api
  module V3
    class Casters::FollowsController < ApiController

      def create
        @caster = Caster.find(params[:caster_id])
        caster_subscription = new_caster_subscription
        caster_subscription.create_in_mailchimp
        if caster_subscription.save
          render json: caster_subscription,
                 serializer: CasterFollowSerializer,
                 status: :created
        else
          render json: caster_subscription.errors, status: :bad_request
        end
      end

      def destroy
        caster_subscription = CasterFollow.find(params[:id])
        if caster_subscription.destroy_in_mailchimp
          render json: caster_subscription.destroy,
                 serializer: CasterFollowSerializer,
                 status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

      def new_caster_subscription
        CasterFollow.find_or_initialize_by(
          caster_id: params[:caster_id],
          user_id: current_user.id
        )
      end

    end
  end
end
