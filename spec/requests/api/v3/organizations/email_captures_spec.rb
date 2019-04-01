require 'spec_helper'

RSpec.describe "Organization Email Captures Endpoint", type: :request do
  let(:email) { 'boba@fett.com' }

  subject do
    post '/api/v3/organizations/email_captures', params: { email: email }
  end

  it "backgrounds job to subscribe email to mobile blogger interest list" do
    expect(BackgroundJob).to receive(:perform_later).with(
      "Outreach::AddEmailToMobileBloggerInterestList",
      "call",
      email
    )
    subject
  end

  context "when production messaging enabled" do
    before do
      env = double(production_messaging_enabled: 'true')
      allow(Figaro).to receive(:env).and_return(env)
      allow(SlackService).to receive(
        :send_new_blogger_email_capture
      ).and_return(true)
    end

    it "sends message to Slack" do
      expect(SlackService).to receive(
        :send_new_blogger_email_capture
      ).with(email)
      subject
    end
  end
end