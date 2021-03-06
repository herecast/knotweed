# frozen_string_literal: true

class ListservDigestMailer < ActionMailer::Base
  require 'htmlcompressor'

  layout nil
  default from: 'null@null.disabled',
          to: 'null@null.disabled'

  add_template_helper ContentsHelper
  add_template_helper FeaturesHelper
  add_template_helper EmailTemplateHelper
  add_template_helper DigestImageServiceHelper

  def digest(digest_record)
    @digest = digest_record
    @listserv = digest_record.listserv
    compressor = HtmlCompressor::Compressor.new(options = { preserve_line_breaks: true })

    template = @digest.template? ? @digest.template : 'outlook_news_template'

    # note: we used to have a conditional on skip_premailer based on template,
    # but having read the docs in more detail for the premailer-rails gem,
    # it's clear that was skipping premailer regardless, because the gem just looks for
    # the presence of the header. Values of true or false are treated equivalently.
    mail_instance = mail(subject: @digest.subject, template_name: template.to_s, skip_premailer: true)
    mail_instance.delivery_handler = self
    string_body = mail_instance.body.to_s
    mail_instance.body = compressor.compress(string_body)
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
      campaign = MailchimpService.create_campaign(@digest, mail_instance.body.to_s)
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
