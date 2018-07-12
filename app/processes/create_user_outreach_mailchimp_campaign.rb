class CreateUserOutreachMailchimpCampaign

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(user:, type:)
    @user = user
    @type = type
  end

  def call
    CreateMailchimpSegmentForNewUser.call(@user) unless @user.mc_segment_id.present?
    response = create_campaign
    MailchimpService::UserOutreach.schedule_campaign(response['id'])
  end

  private

    def create_campaign
      MailchimpService::UserOutreach.create_campaign(
        user: @user,
        subject: send("first_#{@type}_email")[:subject],
        template_id: send("first_#{@type}_email")[:template_id]
      )
    end

    def first_market_post_email
      {
        subject: Rails.configuration.subtext.email_outreach.initial_market_post.subject,
        template_id: Rails.configuration.subtext.email_outreach.initial_market_post.template_id
      }
    end

    def first_event_email
      {
        subject: Rails.configuration.subtext.email_outreach.initial_event_post.subject,
        template_id: Rails.configuration.subtext.email_outreach.initial_event_post.template_id
      }
    end

end