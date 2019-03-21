require 'spec_helper'

RSpec.describe 'MailchimpWebook Requests', type: :request do
  describe "GET /api/v3/mailchimp_webhooks" do
    subject { get '/api/v3/mailchimp_webhooks' }

    it "validates the endpoint with ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "POST /api/v3/mailchimp_webhooks" do
    before do
      allow(Outreach::DestroyUserOrganizationSubscriptions).to receive(
        :call
      ).and_return true
    end
    subject { post '/api/v3/mailchimp_webhooks', params: mailchimp_webhook_content }

    it "calls to destroy organization_subscriptions with webhook params" do
      expect(Outreach::DestroyUserOrganizationSubscriptions).to receive(
        :call
      ).with(mailchimp_webhook_content)
      subject
    end
  end
end