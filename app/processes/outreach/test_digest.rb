module Outreach
  class TestDigest
    include ContentsHelper
    include EmailTemplateHelper
    include DigestImageServiceHelper

    OUTLOOK_TEMPLATE_PATH = "#{Rails.root}/app/views/listserv_digest_mailer/outlook_news_template.html.erb"

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(digest:, user:)
      @digest   = digest
      @listserv = digest.listserv
      @user     = user
    end

    def call
      list = MailchimpService::UserOutreach.create_list(random_digest_name)
      subscribe_user_to_list(list['id'])
      campaign = new_test_campaign(list['id'])
      MailchimpService.put_campaign_content(campaign['id'], build_html)
      BackgroundJob.set(wait: 4.minutes).perform_later('Outreach::TestDigest', 'send_campaign', campaign['id'], list['id'])
    end

    def self.send_campaign(campaign_id, list_id)
      MailchimpService.send_campaign(campaign_id)
      BackgroundJob.set(wait: 2.minutes).perform_later('Outreach::TestDigest', 'clean_up_campaign', campaign_id, list_id)
    end

    def self.clean_up_campaign(campaign_id, list_id)
      MailchimpService::UserOutreach.delete_campaign(campaign_id)
      MailchimpService::UserOutreach.delete_list(list_id)
    end

    private

      def random_digest_name
        "test-digest-#{SecureRandom.hex(2)}"
      end

      def subscribe_user_to_list(list_id)
        MailchimpService::UserOutreach.subscribe_user_to_list(
          list_id: list_id,
          user: @user
        )
      end

      def new_test_campaign(list_id)
        MailchimpService::UserOutreach.create_test_campaign(
          list_id: list_id,
          digest: @digest
        )
      end

      def build_html
        ERB.new(File.read(OUTLOOK_TEMPLATE_PATH)).result(binding)
      end

  end
end