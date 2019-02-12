module Outreach
  class DestroyOrganizationSubscriptionInMailchimp
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
      mailchimp_organization_segment_delete_member
      @organization_subscription.update_attribute(:deleted_at, Time.current)
    end

    private

      def mailchimp_organization_segment_delete_member
        mailchimp_connection.lists.static_segment_members_del(mailchimp_master_list_id,
          @organization.mc_segment_id,
          [{ email: @user.email }]
        )
      end

  end
end