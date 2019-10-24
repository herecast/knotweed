# frozen_string_literal: true

module Api
  module V3
    class Organizations::SubscriptionsController < ApiController
      def index
        if params[:query]
          @organizations = Organization.search(params[:query], org_query_opts)
          render json: { organizations: serialized_organizations }, status: :ok
        else
          render json: {}, status: :ok
        end
      end

      def create
        org_subscription = new_org_subscription
        org_subscription.create_in_mailchimp
        if org_subscription.save
          render json: org_subscription,
                 serializer: OrganizationSubscriptionSerializer,
                 status: :created
        else
          render json: org_subscription.errors, status: :bad_request
        end
      end

      def destroy
        org_subscription = OrganizationSubscription.find(params[:id])
        if org_subscription.destroy_in_mailchimp
          render json: org_subscription.destroy,
                 serializer: OrganizationSubscriptionSerializer,
                 status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

      def serialized_organizations
        @organizations.results.map do |org|
          {
            id: org.id,
            name: org.name,
            profile_image_url: org.profile_image_url
          }
        end
      end

      def new_org_subscription
        organization = Organization.find(params[:organization_id])
        if organization.user_id.present?
          OrganizationSubscription.find_or_initialize_by(
            caster_id: organization.user_id,
            user_id: current_user.id
          )
        else
          raise ActiveRecord::RecordNotFound
        end
      end

      def org_query_opts
        {
          limit: 10,
          where: {
            archived: {
              in: [false, nil]
            },
            or: [[
              { org_type: %w[Blog Publisher Publication] },
              { org_type: 'Business', biz_feed_active: true }
            ]]
          }
        }
      end
    end
  end
end
