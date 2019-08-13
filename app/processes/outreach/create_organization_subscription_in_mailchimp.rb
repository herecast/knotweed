# frozen_string_literal: true

module Outreach
  class CreateOrganizationSubscriptionInMailchimp
    include MailchimpAPI

    def self.call(*args)
      new(*args).call
    end

    def initialize(organization_subscription)
      @organization_subscription = organization_subscription
      @organization              = organization_subscription.organization
      @user                      = organization_subscription.user
    end

    def call
      conditionally_create_mailchimp_organization_segment
      conditionally_add_user_to_mailchimp_master_list(@user)
      add_member_to_mailchimp_organization_segment
      conditionally_undelete_org_subscription
      @organization.reindex(:active_subscriber_count_data)
      true
    end

    private

    def conditionally_create_mailchimp_organization_segment
      if @organization.mc_segment_id.nil?
        response = mailchimp_connection.lists.static_segment_add(mailchimp_config.master_list_id,
                                                                 @organization.mc_segment_name)
        @organization.update_attribute(:mc_segment_id, response['id'])
      end
    end

    def add_member_to_mailchimp_organization_segment
      mailchimp_connection.lists.static_segment_members_add(mailchimp_config.master_list_id,
                                                            @organization.mc_segment_id,
                                                            [{ email: @user.email }])
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
