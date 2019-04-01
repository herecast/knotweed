require 'spec_helper'

RSpec.describe Outreach::AddEmailToMobileBloggerInterestList do
  describe "::call" do
    before do
      @lists = double(subscribe: true)
      @list_id = 'Tatoine1'
      config = double(mobile_blogger_interest_list_id: @list_id)
      allow(MailchimpAPI).to receive(:config).and_return(config)
      mailchimp = double(lists: @lists)
      allow(Mailchimp::API).to receive(:new).and_return(mailchimp)
    end

    let(:email) { 'jabba@hutt.com' }

    subject { Outreach::AddEmailToMobileBloggerInterestList.call(email) }

    it "subscribes email to mobile blogger interest list in Mailchimp" do
      expect(@lists).to receive(:subscribe).with(
        @list_id,
        { email: email },
        nil,
        'html',
        false
      )
      subject
    end
  end
end