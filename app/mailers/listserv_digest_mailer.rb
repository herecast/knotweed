class ListservDigestMailer < ActionMailer::Base
  layout nil
  default from: 'null@null.disabled',
          to: 'null@null.disabled'

  add_template_helper ContentsHelper
  add_template_helper EmailTemplateHelper

  def digest(digest_record)
    @digest = digest_record
    @listserv = digest_record.listserv

    template = @digest.template? ? @digest.template : "digest"

    mail_instance = mail(subject: @digest.subject, template_name: "#{template}")
    mail_instance.delivery_handler = self
    mail_instance
  end

  # Default handler override
  def self.deliver_mail(mail_instance)
    # Disable default delivery process.
    # It is handled by this mailer instance.
    mail_instance
  end

  def deliver_mail(mail_instance)
    unless @digest.mc_campaign_id?
      campaign = MailchimpService.create_campaign(@digest, mail_instance.body.encoded)
      @digest.update_attribute :mc_campaign_id, campaign[:id]
    end
    BackgroundJob.perform_later(self.class.name, 'send_campaign', @digest)
  end

  # Background for it's own retry schedule
  def self.send_campaign(digest)
    MailchimpService.send_campaign(digest.mc_campaign_id)
    digest.update_attribute :sent_at, Time.current
    digest.listserv.update_attribute :last_digest_send_time, digest.sent_at
  end

end
