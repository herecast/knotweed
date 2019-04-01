# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Outreach::DestroyUserOrganizationSubscriptions do
  describe '::call' do
    before do
      @master_list_id = mailchimp_webhook_content[:data][:list_id]
      env = double(mailchimp_master_list_id: @master_list_id)
      allow(Figaro).to receive(:env).and_return(env)
      user = FactoryGirl.create :user,
                                email: mailchimp_webhook_content['data']['email']
      @org_subscription = FactoryGirl.create :organization_subscription,
                                             user: user,
                                             organization: FactoryGirl.create(:organization),
                                             deleted_at: nil
    end

    subject do
      Outreach::DestroyUserOrganizationSubscriptions.call(
        mailchimp_webhook_content
      )
    end

    it 'marks user organization_subscriptions as deleted' do
      expect { subject }.to change {
        @org_subscription.reload.deleted_at
      }
      subject
    end
  end
end
