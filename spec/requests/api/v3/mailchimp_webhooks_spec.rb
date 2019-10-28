# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MailchimpWebook Requests', type: :request do
  describe 'GET /api/v3/mailchimp_webhooks' do
    subject { get '/api/v3/mailchimp_webhooks' }

    it 'validates the endpoint with ok status' do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe 'POST /api/v3/mailchimp_webhooks' do
    subject { post '/api/v3/mailchimp_webhooks', params: mailchimp_webhook_content }

    context "when webhook list id matches master list id" do
      before do
        @master_list_id = mailchimp_webhook_content[:data][:list_id]
        env = double(
          mailchimp_master_list_id: @master_list_id,
          mailchimp_api_key: 'dummy',
          mailchimp_api_host: 'dummy'
        )
        allow(Figaro).to receive(:env).and_return(env)
        user = FactoryGirl.create :user,
                                  email: mailchimp_webhook_content['data']['email']
        @org_subscription = FactoryGirl.create :organization_subscription,
          user: user,
          caster: FactoryGirl.create(:caster),
          deleted_at: nil
      end

      it 'marks user organization_subscriptions as deleted' do
        expect { subject }.to change {
          @org_subscription.reload.deleted_at
        }
        subject
      end
    end

    context "when list id matches digest list id" do
      before do
        list_id = mailchimp_webhook_content[:data][:list_id]
        config = double(
          digest_list_id: list_id,
          master_list_id: 'other-list-id'
        )
        allow(MailchimpAPI).to receive(:config).and_return(config)
        user = FactoryGirl.create :user,
          email: mailchimp_webhook_content[:data][:email]
        listserv = FactoryGirl.create :listserv,
          mc_list_id: list_id,
          mc_group_name: 'spice anonymous'
        @subscription = FactoryGirl.create :subscription,
          email: user.email,
          listserv_id: listserv.id,
          unsubscribed_at: nil,
          mc_unsubscribed_at: nil
      end

      it "marks user digest subscriptions as unsubscribed" do
        expect{ subject }.to change{
          @subscription.reload.unsubscribed_at
        }.and change{
          @subscription.reload.mc_unsubscribed_at
        }
      end
    end
  end
end
