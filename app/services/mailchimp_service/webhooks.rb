# frozen_string_literal: true

module MailchimpService
  module Webhooks
    include MailchimpAPI
    extend self

    def handle(webhook_body)
      return unless webhook_body[:type] == 'unsubscribe'
      if master_list_id?(webhook_body)
        user = User.find_by(email: webhook_body[:data][:email])
        unsubscribe_user_from_orgs(user) if user
      elsif digest_list_id?(webhook_body)
        unsubscribe_user_from_digests(webhook_body)
      end
    end

    private

    def master_list_id?(webhook_body)
      webhook_body[:data][:list_id] == mailchimp_config.master_list_id
    end

    def digest_list_id?(webhook_body)
      webhook_body[:data][:list_id] == mailchimp_config.digest_list_id
    end

    def unsubscribe_user_from_orgs(user)
      user.caster_follows.each do |caster_follow|
        caster_follow.update_attribute(:deleted_at, Time.current)
      end
    end

    def unsubscribe_user_from_digests(webhook_body)
      mc_list_id = webhook_body[:data][:list_id]
      listservs = Listserv.where(mc_list_id: mc_list_id)
      listservs.each do |listserv|
        subscription = listserv.subscriptions.find_by(email: webhook_body[:data][:email])
        if subscription
          subscription.update_attributes(
            unsubscribed_at: Time.zone.now,
            mc_unsubscribed_at: Time.zone.now
          )
        end
      end
    end
  end
end