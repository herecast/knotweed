module Outreach
  class ScheduleDigest
    include ContentsHelper
    include EmailTemplateHelper
    include DigestImageServiceHelper

    OUTLOOK_TEMPLATE_PATH = "#{Rails.root}/app/views/listserv_digest_mailer/outlook_news_template.html.erb"

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(digest)
      @digest   = digest
      @listserv = digest.listserv
    end

    def call
      unless @digest.mc_campaign_id?
        campaign = MailchimpService.create_campaign(@digest, build_html)
        @digest.update_attribute :mc_campaign_id, campaign[:id]
      end
      BackgroundJob.perform_later('Outreach::ScheduleDigest', 'send_campaign', @digest)
    end

    def self.send_campaign(digest)
      MailchimpService.send_campaign(digest.mc_campaign_id)
      digest.update_attribute :sent_at, Time.current
      digest.listserv.update_attribute :last_digest_send_time, digest.sent_at
    end

    private

      def build_html
        ERB.new(File.read(OUTLOOK_TEMPLATE_PATH)).result(binding)
      end

  end
end