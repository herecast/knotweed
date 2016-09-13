require 'rails_helper'
require 'addressable'

# The below is necessary for environments that do not read application.yml (CI)
ENV['MAILCHIMP_API_HOST'] = "test.com"
ENV['MAILCHIMP_API_KEY'] = "test.key"

RSpec.describe MailchimpService do
  subject { MailchimpService }
  let(:base_url) { Figaro.env.mailchimp_api_host.to_s + '/3.0' }
  let(:auth) { ["user", Figaro.env.mailchimp_api_key] }

  it { is_expected.to respond_to(:subscribe) }
  it { is_expected.to respond_to(:unsubscribe) }

  describe '.subscribe' do
    context 'given a subscription' do
      let(:listserv) { FactoryGirl.create :listserv, mc_list_id: "99ss" }
      let(:subscription) {FactoryGirl.create(:subscription, :confirmed,
                                             listserv: listserv,
                                             name: "Bobby Roberts")}
      let(:subscriber_hash) { Digest::MD5.hexdigest subscription.email }

      let!(:apistub) {
        stub_request(:put,
            "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}"
          ).with(
            basic_auth: auth,
            headers: {
              "Content-Type" => 'application/json',
              "Accept" => 'application/json'
            },
            body: {
              email_type: subscription.email_type,
              status: 'subscribed',
              ip_signup: subscription.confirm_ip,
              timestamp_signup: subscription.created_at.iso8601,
              ip_opt: subscription.confirm_ip,
              timestamp_opt: subscription.confirmed_at.iso8601,
              email_address: subscription.email,
              status_if_new: 'subscribed',
              merge_fields: {
                FNAME: subscription.subscriber_name.split(/\s+/).first,
                LNAME: subscription.subscriber_name.split(/\s+/).last
              }
            }.to_json
          )
      }

      subject {
        MailchimpService.subscribe(subscription)
      }

      it 'does upsert on mailchimp api' do
        subject

        expect(apistub).to have_been_requested
      end

      context "when listserv does not have a mc_list_id" do
        before do
          listserv.update mc_list_id: nil
        end

        it 'raises exception' do
          expect{ subject }.to raise_exception(MailchimpService::MissingListId)
        end
      end

      context 'if response code >= 400' do
        it 'raises exception' do
          apistub.to_return(status: 400)

          expect{ subject }.to raise_exception(MailchimpService::UnexpectedResponse)
        end
      end

      context 'when not confirmed' do
        before do
          subscription.update confirmed_at: nil
        end

        it 'raises exception' do
          expect{ subject }.to raise_error(RuntimeError, "Subscription #{subscription.id} is not confirmed.")
        end
      end

      context 'when unsubscribed' do
        before do
          subscription.update unsubscribed_at: Time.current
        end

        it 'raises exception' do
          expect{ subject }.to raise_error(RuntimeError, "Subscription #{subscription.id} is unsubscribed.")
        end
      end

    end
  end

  describe '.unsubscribe' do
    context 'given a subscription' do
      let(:listserv) { FactoryGirl.create :listserv, mc_list_id: "99ss" }
      let(:subscription) {FactoryGirl.create(:subscription,
                                             :confirmed,
                                             :unsubscribed,
                                             listserv: listserv)}
      let(:subscriber_hash) { Digest::MD5.hexdigest subscription.email }

      let!(:apistub) {
        stub_request(:delete,
          "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}"
        ).with(
          basic_auth: auth,
          headers: {
            "Content-Type" => 'application/json',
            "Accept" => 'application/json'
          }
        )
      }

      subject {
        MailchimpService.unsubscribe(subscription)
      }

      it 'removes member from list on mailchimp api' do
        subject

        expect(apistub).to have_been_requested
      end

      context "when listserv does not have a mc_list_id" do
        before do
          listserv.update mc_list_id: nil
        end

        it 'raises exception' do
          expect{ subject }.to raise_exception(MailchimpService::MissingListId)
        end
      end

      context 'if response code >= 400' do
        it 'raises exception' do
          apistub.to_return(status: 400)

          expect{ subject }.to raise_exception(MailchimpService::UnexpectedResponse)
        end
      end

      context 'when not unsubscribed' do
        before do
          subscription.update unsubscribed_at: nil
        end

        it 'raises exception' do
          expect{ subject }.to raise_error(RuntimeError, "Subscription #{subscription.id} is not unsubscribed.")
        end
      end
    end
  end

  describe '.create_campaign' do
    context 'given a listserv model, and text/html content' do
      let(:listserv) { FactoryGirl.create :listserv, digest_reply_to: 'test@123.test' }
      let(:digest) { FactoryGirl.create :listserv_digest, listserv: listserv }
      let(:content) { "<p>Hello World!</p>" }

      subject { MailchimpService.create_campaign(digest, content) }

      let!(:apistub_create) {
        stub_request(:post,
          "https://#{base_url}/campaigns"
        ).with(
          basic_auth: auth,
          headers: {
            "Content-Type" => 'application/json',
            "Accept" => 'application/json'
          },
          body: hash_including({
            type: 'regular',
            recipients: {
              list_id: listserv.mc_list_id
            },
            settings: {
              subject_line: "#{listserv.name} Digest",
              from_name: listserv.name,
              reply_to: listserv.digest_reply_to
            }
          })
        ).to_return(
          status: 201,
          headers: {
            "Content-Type" => 'application/json',
          },
          body: {
            id: '123abc'
          }.to_json
        )
      }

      let!(:apistub_content) {
        stub_request(:put,
          "https://#{base_url}/campaigns/123abc/content"
        ).with(
          basic_auth: auth,
          headers: {
            "Content-Type" => 'application/json',
            "Accept" => 'application/json'
          },
          body: hash_including({
            html: content
          })
        )
      }



      it 'creates mailchimp campaign with expected attributes' do
        subject
        expect(apistub_create).to have_been_requested
        expect(apistub_content).to have_been_requested
      end

      it 'returns campaign info, including id' do
        expect(subject).to match hash_including({
          id: a_kind_of(String)
        })
      end
    end
  end

  describe '.update_campaign' do
    context 'given a listserv model, and text/html content' do
      let(:listserv) { FactoryGirl.create :listserv }
      let(:digest) { 
        FactoryGirl.create :listserv_digest, 
          listserv: listserv,
          campaign_id: 'daCampId'
      }
      let(:content) { "<p>Hello World!</p>" }

      subject { MailchimpService.update_campaign(digest, content) }

      let!(:apistub_patch) {
        stub_request(:patch,
          "https://#{base_url}/campaigns/#{digest.campaign_id}"
        ).with(
          basic_auth: auth,
          headers: {
            "Content-Type" => 'application/json',
            "Accept" => 'application/json'
          },
          body: hash_including({
            type: 'regular',
            recipients: {
              list_id: listserv.mc_list_id
            },
            settings: {
              subject_line: "#{listserv.name} Digest",
              from_name: listserv.name,
              reply_to: listserv.post_email
            }
          })
        ).to_return(
          status: 200,
          headers: {
            "Content-Type" => 'application/json',
          },
          body: {
            id: digest.campaign_id
          }.to_json
        )
      }

      let!(:apistub_content) {
        stub_request(:put,
           "https://#{base_url}/campaigns/#{digest.campaign_id}/content"
        ).with(
          basic_auth: auth,
          headers: {
            "Content-Type" => 'application/json',
            "Accept" => 'application/json'
          },
          body: hash_including({
            html: content
          })
        )
      }

      it 'updates mailchimp campaign with expected attributes' do
        subject
        expect(apistub_patch).to have_been_requested
      end

      it 'updates the content on the campaign' do
        subject
        expect(apistub_content).to have_been_requested
      end

      context "when not given content" do
        subject { MailchimpService.update_campaign(digest) }
        let!(:apistub_content) {
          stub_request(:put,
             "https://#{base_url}/campaigns/#{digest.campaign_id}/content"
          ).with(
            basic_auth: auth,
            headers: {
              "Content-Type" => 'application/json',
              "Accept" => 'application/json'
            }
          )
        }

        it 'updates mailchimp campaign with expected attributes' do
          subject
          expect(apistub_patch).to have_been_requested
        end

        it 'does not try to update the content' do
          subject
          expect(apistub_content).to_not have_been_requested
        end
      end
    end
  end

  describe '.send_campaign' do
    context 'given a campaign id' do
      let(:campaign_id) { "98fds90" }

      subject { MailchimpService.send_campaign(campaign_id) }

      let!(:apistub) {
        stub_request(:post,
          "https://#{base_url}/campaigns/#{campaign_id}/actions/send"
        ).with(
          basic_auth: auth,
          headers: {
            "Content-Type" => 'application/json',
            "Accept" => 'application/json'
          }
        )
      }

      it 'triggers campaign send on mailchimp api' do
        subject
        expect(apistub).to have_been_requested
      end

      context 'if response code >= 400' do
        it 'raises exception' do
          apistub.to_return(status: 400)

          expect{ subject }.to raise_exception(MailchimpService::UnexpectedResponse)
        end
      end
    end
  end
end
