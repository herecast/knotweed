# frozen_string_literal: true

module Outreach
  class CreateCasterFollowInMailchimp
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
      conditionally_create_mailchimp_caster_segment
      conditionally_add_user_to_mailchimp_master_list(@user)
      add_member_to_mailchimp_caster_segment
      conditionally_undelete_caster_follow
      true
    end

    private

    def conditionally_create_mailchimp_caster_segment
      if @caster.mc_followers_segment_id.nil?
        response = mailchimp_connection.lists.static_segment_add(mailchimp_config.master_list_id,
                                                                 @caster.mc_followers_segment_name)
        @caster.update_attribute(:mc_followers_segment_id, response['id'])
      end
    end

    def add_member_to_mailchimp_caster_segment
      mailchimp_connection.lists.static_segment_members_add(mailchimp_config.master_list_id,
                                                            @caster.mc_followers_segment_id,
                                                            [{ email: @user.email }])
    end

    def conditionally_undelete_caster_follow
      if caster_follow_persisted_and_deleted?
        @caster_follow.deleted_at = nil
      end
    end

    def caster_follow_persisted_and_deleted?
      @caster_follow.persisted? && \
        @caster_follow.deleted_at.present?
    end
  end
end
