require 'rails_helper'

RSpec.describe ListservDigestJob do
  context 'Given a listserv model' do
    let(:listserv) { FactoryGirl.create :listserv }
    subject { described_class.new.perform(listserv) }

    before do
      # mock so we aren't making api calls
      allow(MailchimpService).to receive(:create_campaign).and_return(
        id: 'theCampaignId'
      )
      allow(MailchimpService).to receive(:send_campaign)
    end


    context 'Listserv digest is enabled' do
      before do
        listserv.update send_digest: true,
          digest_reply_to: 'test@test.com',
          digest_subject: 'This is the STUFF!',
          last_digest_generation_time: 1.day.ago
      end

      context 'active subscribers' do
        let!(:subscriptions) { FactoryGirl.create_list :subscription, 3, :subscribed, listserv: listserv }

        context 'listserv is internal list' do
          before do
            listserv.update list_type: 'internal_list'
          end

          context 'verified content exists' do
            let!(:listserv_content_verified_after) {
              FactoryGirl.create_list :listserv_content, 3,
                :verified,
                verified_at: listserv.last_digest_generation_time + 1.hour,
                listserv: listserv
            }

            let!(:listserv_content_verified_before) {
              FactoryGirl.create :listserv_content,
                :verified,
                verified_at: listserv.last_digest_generation_time - 1.hour,
                listserv: listserv
            }

            it 'creates a digest record' do
              expect{ subject }.to change{
                ListservDigest.count
              }.to(1)

              expect(ListservDigest.last.listserv).to eql listserv
            end

            it 'sets instance information' do
              subject
              digest = ListservDigest.last
              expect(digest.subject).to eql listserv.digest_subject
              expect(digest.reply_to).to eql listserv.digest_reply_to
              expect(digest.from_name).to eql listserv.name
              expect(digest.template).to eql listserv.template
              expect(digest.subscription_ids).to match_array listserv.subscriptions.pluck(:id)
              expect(digest.title).to eql listserv.digest_subject
            end

            it 'sends digest' do
              mail = double()
              expect(ListservDigestMailer).to receive(:digest).with(
                an_instance_of(ListservDigest)
              ).and_return(mail)
              expect(mail).to receive(:deliver_now)

              subject
            end

            it 'updates last_digest_generation_time to now' do
              Timecop.freeze(Time.current) do
                expect{ subject }.to change{
                  listserv.reload.last_digest_generation_time.to_i
                }.to Time.current.to_i
              end
            end

            describe '#listserv_contents' do
              it 'is the listserv_contents verified after last generation' do
                subject
                expect(ListservDigest.last.listserv_contents.to_a).to match_array listserv_content_verified_after.to_a
              end

              context 'when content exists for blacklisted subscribers' do
                let(:blacklisted_content) {
                  listserv_content_verified_after.first
                }
                before do
                  blacklisted_content.subscription.update blacklist: true
                end

                it 'does not include the content from the blacklisted subscriber' do
                  subject
                  listserv_contents = ListservDigest.last.listserv_contents.to_a
                  expect(listserv_contents).to_not include blacklisted_content
                end
              end

              context 'some content was removed by moderator' do
                let(:deleted_content) {
                  listserv_content_verified_after.first
                }
                before do
                  deleted_content.update! deleted_at: Time.current
                end

                it 'does not included removed content' do
                  subject
                  listserv_contents = ListservDigest.last.listserv_contents.to_a
                  expect(listserv_contents).to_not include deleted_content
                end
              end
            end

            context 'when digest never generated before;' do
              before do
                listserv.update! last_digest_generation_time: nil
              end

              context 'content exists verified less than 1 month ago;' do
                let!(:listserv_content) {
                  FactoryGirl.create :listserv_content,
                    :verified,
                    listserv: listserv,
                    verified_at: 27.days.ago
                 }

                it 'creates a digest record referencing that content' do
                  subject
                  digest = ListservDigest.last
                  expect(digest.listserv_content_ids).to include(listserv_content.id)
                end
              end
            end
          end
        end

        context 'custom query with content matching' do
          before do
            listserv.update!(
              list_type: 'custom_digest',
              digest_query: 'SELECT * FROM contents ORDER BY id LIMIT 2'
            )
          end

          let!(:content) { FactoryGirl.create_list :content, 3 }

          context 'with no campaigns'  do
            it 'creates a digest record'do
              expect{ subject }.to change{
                ListservDigest.count
              }.to(1)

              expect(ListservDigest.last.listserv).to eql listserv
            end

            it 'sets instance information' do
              subject
              digest = ListservDigest.last
              expect(digest.subject).to eql listserv.digest_subject
              expect(digest.reply_to).to eql listserv.digest_reply_to
              expect(digest.from_name).to eql listserv.name
              expect(digest.template).to eql listserv.template
              expect(digest.subscription_ids).to match_array listserv.subscriptions.pluck(:id)
              expect(digest.title).to eql listserv.digest_subject
            end

            it 'sets up #contents with results from query' do
              subject
              digest = ListservDigest.last
              expect(digest.contents).to eql listserv.contents_from_custom_query
            end

          end

          context 'with active campaigns' do
            let!(:campaign_1) { FactoryGirl.create :campaign,
              listserv: listserv,
              title: 'Camp1',
              community_ids: [listserv.subscriptions.first.user.location_id],
              sponsored_by: Faker::Company.name,
              promotion_ids: [FactoryGirl.create(:promotion_banner).promotion.id],
              preheader: 'Camp1 PREHEADER'
            }

            let!(:campaign_2) {FactoryGirl.create :campaign,
              title: 'camp2',
              listserv: listserv,
              community_ids: [listserv.subscriptions.last.user.location_id],
              sponsored_by: Faker::Company.name,
              digest_query: 'SELECT * FROM contents'
            }

            it 'creates digest records for each campaign' do
              expect{ subject }.to change{
                ListservDigest.count
              }.to(2)
            end

            describe 'subscription_ids' do
              it 'should be populated by listserv subscriptions filtered by location_ids' do
                subject
                # get campaign 1 digest
                digest = ListservDigest.where(listserv: listserv).
                  select{ |ld| ld.location_ids == campaign_1.community_ids }.first
                expect(digest.subscription_ids).to match_array [listserv.subscriptions.first.id]
              end
            end

            it 'uses the custom digest query when specified' do
              subject
              # get the digest corresponding to campaign2
              digest = ListservDigest.where(listserv: listserv).select{ |ld| ld.location_ids == campaign_2.community_ids }.first
              expect(digest.contents).to match_array(Content.all)
            end

            it 'sets instance information for each digest' do
              subject
              ListservDigest.where(listserv: listserv).each do |digest|
                # select campaign by community_ids so we can know which campaign to match against
                campaign = Campaign.where(listserv: listserv).select{|c| c.community_ids == digest.location_ids }.first
                expect(digest.subject).to eql listserv.digest_subject
                expect(digest.reply_to).to eql listserv.digest_reply_to
                expect(digest.from_name).to eql listserv.name
                expect(digest.template).to eql listserv.template
                expect(digest.sponsored_by).to eql campaign.sponsored_by
                expect(digest.promotion_ids).to eql campaign.promotion_ids
                expect(digest.title).to eql campaign.title
                expect(digest.preheader).to eql campaign.preheader
              end
            end
          end

          it 'sends digest' do
            mail = double()
            expect(ListservDigestMailer).to receive(:digest).with(
              an_instance_of(ListservDigest)
            ).and_return(mail)
            expect(mail).to receive(:deliver_now)

            subject
          end

          it 'updates last_digest_generation_time to now' do
            Timecop.freeze(Time.current) do
              expect{ subject }.to change{
                listserv.reload.last_digest_generation_time.to_i
              }.to Time.current.to_i
            end
          end
        end
      end
    end
  end
end
