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

            context 'when a digest does not have enough posts' do
              let(:threshold_digest) { FactoryGirl.create :listserv, digest_query: 'SELECT * FROM CONTENTS LIMIT 1', post_threshold: 5 }
              it 'does not create a digest if posts are below post_threshold' do
                expect { ListservDigestJob.new.perform(threshold_digest) }.to_not change{
                  ListservDigest.count
                }
              end
            end

            it 'sets up #contents with results from query' do
              subject
              digest = ListservDigest.last
              expect(digest.contents).to eql listserv.contents_from_custom_query
            end

          end

          it 'sends digest' do
            mail = double()
            expect(Outreach::ScheduleDigest).to receive(:call).with(
              an_instance_of(ListservDigest)
            )
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
