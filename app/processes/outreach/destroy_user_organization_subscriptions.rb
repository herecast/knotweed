# frozen_string_literal: true

module Outreach
  class DestroyUserOrganizationSubscriptions
    include MailchimpAPI

    def self.call(*args)
      new(*args).call
    end

    def initialize(webhook_body)
      @webhook_body = webhook_body
    end

    def call
      return unless unsubscribe_webhook?
      return unless correct_list_id?
      return unless user

      unsubscribe_user_from_orgs
    end

    private

    def unsubscribe_webhook?
      # in case we begin to accept different types in future
      @webhook_body[:type] == 'unsubscribe'
    end

    def correct_list_id?
      @webhook_body[:data][:list_id] == mailchimp_master_list_id
    end

    def user
      @user ||= User.find_by(email: @webhook_body[:data][:email])
    end

    def unsubscribe_user_from_orgs
      user.organization_subscriptions.each do |org_subscription|
        org_subscription.update_attribute(:deleted_at, Time.current)
      end
    end
  end
end
