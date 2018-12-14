module Outreach
  class CreateUserHookCampaign
    def self.call(*args)
      self.new(*args).call
    end

    def initialize(user:, action:)
      @user   = user
      @action = action
    end

    def call
      CreateMailchimpSegmentForNewUser.call(@user) unless @user.mc_segment_id.present?
      response = create_campaign
      MailchimpService::UserOutreach.schedule_campaign(response['id'])
    end

    private

    def email_config
      Rails.configuration.subtext.email_outreach
    end

    def create_campaign
      MailchimpService::UserOutreach.create_campaign(
        user: @user,
        subject: email_config.send(@action).subject,
        template_id: email_config.send(@action).template_id
      )
    end
  end
end
