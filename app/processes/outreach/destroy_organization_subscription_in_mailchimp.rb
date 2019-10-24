# frozen_string_literal: true

module Outreach
  class DestroyOrganizationSubscriptionInMailchimp
    include MailchimpAPI

    def self.call(*args)
      new(*args).call
    end

    def initialize(organization_subscription)
      @organization_subscription = organization_subscription
      @caster                    = organization_subscription.caster
      @user                      = organization_subscription.user
    end

    def call
      mailchimp_caster_segment_delete_member
      @organization_subscription.update_attribute(:deleted_at, Time.current)
      @caster.organization&.reindex(:active_subscriber_count_data)
    end

    private

    def mailchimp_caster_segment_delete_member
      mailchimp_connection.lists.static_segment_members_del(mailchimp_config.master_list_id,
                                                            @caster.mc_followers_segment_id,
                                                            [{ email: @user.email }])
    end
  end
end
