module Outreach
  class CreateOrganizationSubscriptionInMailchimp
    include MailchimpAPI

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(organization_subscription)
      @organization_subscription = organization_subscription
      @organization              = organization_subscription.organization
      @user                      = organization_subscription.user
    end

    def call
      conditionally_create_mailchimp_organization_segment
      conditionally_add_user_to_mailchimp_master_list
      add_member_to_mailchimp_organization_segment
      conditionally_undelete_org_subscription
      true
    end

    private

      def conditionally_create_mailchimp_organization_segment
        if @organization.mc_segment_id.nil?
          response = mailchimp_connection.lists.static_segment_add(mailchimp_master_list_id,
            @organization.mc_segment_name
          ) 
          @organization.update_attribute(:mc_segment_id, response['id'])
        end
      end

      def conditionally_add_user_to_mailchimp_master_list
        response = mailchimp_connection.lists.member_info(mailchimp_master_list_id,
          [{ email: @user.email }]
        )
        unless response['success_count'] == 1 && \
          response['data'][0]['status'] == 'subscribed'
          subscribe_user_to_mailchimp_list
        end
      end

      def subscribe_user_to_mailchimp_list
        mailchimp_connection.lists.subscribe(mailchimp_master_list_id,
          { email: @user.email }, nil, 'html', false
        )
      end

      def add_member_to_mailchimp_organization_segment
        mailchimp_connection.lists.static_segment_members_add(mailchimp_master_list_id,
          @organization.mc_segment_id,
          [{ email: @user.email }]
        )
      end

      def conditionally_undelete_org_subscription
        if organization_subscription_persisted_and_deleted?
          @organization_subscription.deleted_at = nil
        end
      end

      def organization_subscription_persisted_and_deleted?
        @organization_subscription.persisted? && \
          @organization_subscription.deleted_at.present?
      end

  end
end