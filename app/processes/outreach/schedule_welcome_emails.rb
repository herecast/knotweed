# frozen_string_literal: true

module Outreach
  class ScheduleWelcomeEmails
    def self.call(*args)
      new(*args).call
    end

    def initialize(user)
      @user = user
    end

    def call
      ordered_steps.map do |step|
        create_campaign(step)
      end.each_with_index do |response, index|
        MailchimpService::UserOutreach.schedule_campaign(response['id'],
                                                         timing: Time.current + (index * 4).days)
      end
    end

    private

    def ordered_steps
      %w[
        welcome
        bookmarking
        subscribe_to_digests
        finding_comments
      ]
    end

    def email_config
      Rails.configuration.subtext.email_outreach
    end

    def create_campaign(step)
      MailchimpService::UserOutreach.create_campaign(
        user: @user,
        subject: email_config.send(step).subject,
        template_id: email_config.send(step).template_id
      )
    end
  end
end
