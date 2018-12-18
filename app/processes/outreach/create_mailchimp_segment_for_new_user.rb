# frozen_string_literal: true

module Outreach
  class CreateMailchimpSegmentForNewUser
    def self.call(*args)
      new(*args).call
    end

    def initialize(user, opts = {})
      @user = user
      @opts = opts
    end

    def call
      unless @user.mc_segment_id.present?
        MailchimpService::NewUser.subscribe_to_list(@user)
        create_user_specific_mc_segment
        add_user_to_user_specific_mc_segment
      end
      schedule_welcome if @opts[:schedule_welcome_emails] == true
      schedule_blogger_emails if @opts[:schedule_blogger_emails] == true
    end

    private

    def create_user_specific_mc_segment
      response = MailchimpService::NewUser.create_segment(@user)
      if response['id'].present?
        @user.update_attribute(:mc_segment_id, response['id'])
      else
        raise "Error creating Mailchimp segment for user with id: #{@user.id}"
      end
    end

    def add_user_to_user_specific_mc_segment
      response = MailchimpService::NewUser.add_to_segment(@user)
      if response['error_count'] > 0
        raise "Error adding user to user specific Mailchimp segment: #{response['errors'].join(', ')}"
      end
    end

    def schedule_welcome
      ScheduleWelcomeEmails.call(@user)
    end

    def schedule_blogger_emails
      ScheduleBloggerEmails.call(
        action: 'blogger_welcome_and_reminder',
        user: @user,
        organization: @opts[:organization]
      )
    end
  end
end
