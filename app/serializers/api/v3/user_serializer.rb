# frozen_string_literal: true

module Api
  module V3
    class UserSerializer < ActiveModel::Serializer
      attributes :id,
                 :name,
                 :email,
                 :created_at,
                 :location,
                 :listserv_id,
                 :listserv_name,
                 :test_group,
                 :user_image_url,
                 :events_ical_url,
                 :skip_analytics,
                 :managed_organization_ids,
                 :can_publish_news?,
                 :location_confirmed,
                 :has_had_bookmarks,
                 :is_blogger,
                 :organization_subscriptions,
                 :organization_hides

      def listserv_id
        object.location.try(:listserv).try(:id)
      end

      def listserv_name
        object.location.try(:listserv).try(:name)
      end

      def user_image_url
        object.try(:avatar).try(:url)
      end

      def events_ical_url
        serialization_options[:events_ical_url] if object.public_id.present?
      end

      def managed_organization_ids
        if context.present? && context[:current_ability]
          orgs = Organization.not_archived.with_role(:manager, object)
          (orgs + orgs.map(&:get_all_children).flatten).map(&:id).uniq
        else
          []
        end
      end

      def is_blogger
        object.has_role?(:blogger)
      end

      def location
        {
          id: object.location.id,
          city: object.location.city,
          state: object.location.state
        }
      end

      def organization_subscriptions
        object.organization_subscriptions.active.map do |org_subscription|
          OrganizationSubscriptionSerializer.new(org_subscription, root: false)
        end
      end

      def organization_hides
        object.organization_hides.active.map do |organization_hide|
          OrganizationHideSerializer.new(organization_hide, root: false)
        end
      end
    end
  end
end
