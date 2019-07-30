# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ListservDigestJob do
  context 'Given a listserv model' do
    let(:listserv) { FactoryGirl.create :listserv, send_digest: true, digest_reply_to: 'test@test.com',
                        digest_subject: 'This is the STUFF!', last_digest_generation_time: 1.day.ago }
    subject { described_class.new.perform(listserv, Time.current.to_i) }

    before do
      # mock so we aren't making api calls
      allow(MailchimpService).to receive(:create_campaign).and_return(
        id: 'theCampaignId'
      )
      allow(MailchimpService).to receive(:send_campaign)
    end

    context 'with no subscriptions' do
      it 'should not create any digests' do
        expect { subject }.to_not change {
          ListservDigest.count
        }
      end
    end

    context 'with subscribers in one location' do
      let(:location) { FactoryGirl.create :location }
      let!(:subscriptions) do
        FactoryGirl.create_list :subscription, 3, :subscribed, listserv: listserv,
          user: FactoryGirl.create(:user, location: location)
      end

      context 'but with no content' do
        it 'should not create any digests' do
          expect { subject }.to_not change {
            ListservDigest.count
          }
        end
      end

      context 'with content' do
        let!(:content) { FactoryGirl.create :content, :news, location: location, pubdate: 1.hour.ago }

        it 'should only create one digest' do
          expect { subject }.to change {
            ListservDigest.count
          }.by(1)
        end

        it 'should assign the listserv attributes to the digest' do
          subject
          digest = ListservDigest.last
          expect(digest.listserv).to eql listserv
          expect(digest.subject).to eql listserv.digest_subject
          expect(digest.reply_to).to eql listserv.digest_reply_to
          expect(digest.template).to eql listserv.template
        end

        it 'sends digest' do
          mail = double
          expect(ListservDigestMailer).to receive(:digest).with(
            an_instance_of(ListservDigest)
            ).and_return(mail)
          expect(mail).to receive(:deliver_now)
          subject
        end

        it 'updates last_digest_generation_time to now', freeze_time: true do
          expect { subject }.to change {
            listserv.reload.last_digest_generation_time.to_i
          }.to Time.current.to_i
        end
      end
    end

    context 'with multiple subscribers in multiple locations' do
      let(:loc1) { FactoryGirl.create :location }
      let(:loc2) { FactoryGirl.create :location }
      let!(:sub1) { FactoryGirl.create :subscription, :subscribed, listserv: listserv, user: FactoryGirl.create(:user, location: loc1) }
      let!(:sub2) { FactoryGirl.create :subscription, :subscribed, listserv: listserv, user: FactoryGirl.create(:user, location: loc2) }
      let!(:content1) { FactoryGirl.create :content, :news, pubdate: 1.hour.ago, location: loc1 }
      let!(:content2) { FactoryGirl.create :content, :news, pubdate: 1.hour.ago, location: loc2 }

      it 'should create multiple digests' do
        expect { subject }.to change {
          ListservDigest.count
        }.by(2)
      end

      it 'should create digests with the correct subscribers' do
        subject
        ld1 = ListservDigest.where("content_ids @> ARRAY[?]", content1.id).first
        expect(ld1.subscription_ids).to match_array [sub1.id]
        ld2 = ListservDigest.where("content_ids @> ARRAY[?]", content2.id).first
        expect(ld2.subscription_ids).to match_array [sub2.id]
      end
    end

    context 'with a campaign in one location' do
      let(:loc1) { FactoryGirl.create :location }
      let!(:subscription) { FactoryGirl.create :subscription, :subscribed, listserv: listserv, user: FactoryGirl.create(:user, location: loc1) }
      let!(:content) { FactoryGirl.create :content, :news, pubdate: 1.hour.ago, location: loc1 }
      let!(:campaign) { FactoryGirl.create :campaign, listserv: listserv, community_ids: [loc1.id], title: 'Different title', preheader: 'Different preheader' }

      it 'should use the campaign attributes for the digest' do
        subject
        new_digest = ListservDigest.last
        expect(new_digest.title).to eql campaign.title
        expect(new_digest.preheader).to eql campaign.preheader
      end
    end
  end
end
