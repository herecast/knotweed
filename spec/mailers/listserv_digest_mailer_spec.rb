require 'rails_helper'

RSpec.describe ListservDigestMailer do
  describe '.digest' do
    context 'Given a listserv digest record' do
      let(:listserv) { FactoryGirl.create :listserv, promotion_ids: [promotion.id] }
      let(:listserv_contents) { FactoryGirl.create_list :listserv_content, 3, :verified }
      let(:contents) { FactoryGirl.create_list :content, 3 }
      let!(:promotion) { FactoryGirl.create :promotion, promotable_type: 'PromotionBanner' }
      let!(:promotion_banner) { FactoryGirl.create :promotion_banner, promotion: promotion }
      let(:market_post) { FactoryGirl.create :market_post }

      let!(:listserv_digest) {
        FactoryGirl.create :listserv_digest,
          listserv: listserv,
          listserv_contents: listserv_contents,
          subject: 'A test subject',
          contents: contents,
          mc_campaign_id: nil
       }

      describe "delivery" do
        subject { described_class.digest(listserv_digest).deliver_now }

        before do
          allow(MailchimpService).to receive(:create_campaign).and_return(
            id: 'theCampaignId'
          )
        end

        it 'direct email delivery is disabled' do
          expect{ subject }.to_not change{
            ActionMailer::Base.deliveries.count
          }.from(0)
        end

        it 'passes the generated content, and listserv digest to MailchimpService.create_campaign' do
          mail = described_class.digest(listserv_digest)
          #this line will be needed once we're back to using premailer for all
          #templates.

          # mail = Premailer::Rails::Hook.perform(mail)

          expect(MailchimpService).to receive(:create_campaign).with(
            listserv_digest,
            mail.body.to_s
          ).and_return(id: 'campaignid')

          mail.deliver_now
        end

        it 'backgrounds campaign send' do
          expect{subject}.to have_enqueued_job(BackgroundJob).with(
            'ListservDigestMailer',
            'send_campaign',
            listserv_digest
          )
        end

        it 'updates the mc_campaign_id on digest record' do
          expect{ subject }.to change{
            listserv_digest.reload.mc_campaign_id
          }.to 'theCampaignId'
        end

        context 'digest already has a mc_campaign_id' do
          before do
            listserv_digest.update! mc_campaign_id: '12345'
          end

          it 'does not try to create another campaign' do
            mail = described_class.digest(listserv_digest)
            expect(MailchimpService).to_not receive(:create_campaign)
            mail.deliver_now
          end
        end

        context 'when a listserv digest has a template' do
          it 'defaults to the digest template' do
            expect_any_instance_of(ListservDigestMailer).to receive(:mail).with(subject: listserv_digest.subject, template_name: 'digest', skip_premailer: true).and_return(Mail::Message.new)
            described_class.digest(listserv_digest).deliver_now
          end

          it 'uses the template for the listserv' do
            listserv_digest.template = "test"
            expect_any_instance_of(ListservDigestMailer).to receive(:mail).with(subject: listserv_digest.subject, template_name: "#{listserv_digest.template}", skip_premailer: false).and_return(Mail::Message.new)
            described_class.digest(listserv_digest).deliver_now
          end
        end

        context 'when using a custom footer' do
          let!(:unencoded_tag) { ("*|UNSUB|*") }
          let(:footer_markup) { "<a href=\"#{unencoded_tag}\">unsubscribe</a>" }
          
          before do
            listserv.update! digest_footer: footer_markup
          end

          it 'does not encode mailchimp merge tags in links' do
            mail = described_class.digest(listserv_digest)
            expect(mail.body).not_to include "%7C"
            expect(mail.body).to include unencoded_tag
          end
        end

        describe '.send_campaign' do
          before do
            allow(MailchimpService).to receive(:send_campaign)
          end

          context 'Given a digest record' do
            before do
              listserv_digest.update!(
                mc_campaign_id: 'theCampaignID',
                sent_at: nil
              )
            end
            subject { described_class.send_campaign(listserv_digest) }

            it 'sends the digest campaign through mailchimp' do
              expect(MailchimpService).to receive(:send_campaign).with('theCampaignID')
              subject
            end

            it 'updates the sent_at time on digest record' do
              expect{subject}.to change{
                listserv_digest.reload.sent_at
              }.from(nil).to instance_of(ActiveSupport::TimeWithZone)
            end

            it 'updates the last_digest_send_time on listserv record' do
              expect{ subject }.to change{
                listserv.reload.last_digest_send_time
              }.to instance_of(ActiveSupport::TimeWithZone)
            end

          end
        end
      end

      describe 'subject' do
        subject { described_class.digest(listserv_digest).subject }
        context 'When listserv digest has a subject' do

          before do
            listserv_digest.update(subject: 'A fine subject')
          end

          it { is_expected.to eql 'A fine subject' }
        end
      end

      describe 'generated body' do
        around(:each) do |example|
          old_consumer_host = ENV["DEFAULT_CONSUMER_HOST"]
          ENV["DEFAULT_CONSUMER_HOST"] = "test.test"

          example.run

          ENV["DEFAULT_CONSUMER_HOST"] = old_consumer_host
        end
        subject { described_class.digest(listserv_digest).body.encoded }

        context 'when the template is for listserv digest' do
          before do
            listserv_digest.update(
              template: 'digest',
              promotion_ids: [promotion.id]
            )
          end

          it 'displays the banner ad correctly' do
            expect(subject).to include "digest-banner"
          end

          it 'includes all the listserv content titles' do
            listserv_contents.each do |content|
              expect(subject).to include content.subject
            end
          end

          it 'includes listserv contents sender names' do
            listserv_contents.each do |content|
              expect(subject).to include content.sender_name
            end
          end

          it 'includes the author email' do
            listserv_contents.each do |content|
              expect(subject).to include content.sender_email
            end
          end

          it 'includes the date for the content post' do
            listserv_contents.each do |content|
              date = content.verified_at.strftime('%m/%d/%y')
              time = content.verified_at.strftime('%-l:%M %p')
              expect(subject).to match(/#{date}\s+#{time}/)
            end
          end
        end

        context 'when the template is for custom content query' do
          subject { described_class.digest(listserv_digest).body }

          before do
            listserv_digest.update!(template: 'outlook_news_template')
          end

          it 'includes all the content titles' do
            contents.each do |content|
              expect(subject).to include content.title
            end
          end

        end

      end
    end

  end

end
