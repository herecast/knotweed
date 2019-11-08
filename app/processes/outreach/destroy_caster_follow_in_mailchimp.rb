# frozen_string_literal: true

module Outreach
  class DestroyCasterFollowInMailchimp
    include MailchimpAPI

    def self.call(*args)
      new(*args).call
    end

    def initialize(caster_follow)
      @caster_follow = caster_follow
      @caster        = caster_follow.caster
      @user          = caster_follow.user
    end

    def call
      mailchimp_caster_segment_delete_member
      @caster_follow.update_attribute(:deleted_at, Time.current)
      true
    end

    private

    def mailchimp_caster_segment_delete_member
      mailchimp_connection.lists.static_segment_members_del(mailchimp_config.master_list_id,
                                                            @caster.mc_followers_segment_id,
                                                            [{ email: @user.email }])
    end
  end
end
