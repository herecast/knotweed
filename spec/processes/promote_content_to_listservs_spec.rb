require 'rails_helper'

RSpec.describe PromoteContentToListservs do
  let(:user) { FactoryGirl.create :user }
  let(:remote_ip) { '1.1.1.1' }
  let(:listservs) { FactoryGirl.create_list :listserv, 3 }
  let(:consumer_app) { FactoryGirl.create :consumer_app }
  let(:content) { FactoryGirl.create :content, created_by: user }

  before do
    listservs.each do |ls|
      ls.update locations: [ FactoryGirl.create(:location) ]
    end
  end

  context 'Given content, consumer_app, remote_ip, and *listservs, ' do
    subject { described_class.call(content, consumer_app, remote_ip, *listservs) }

    it 'creates a PromotionListserv for each listserv record' do
      expect{subject}.to change{
        PromotionListserv.count
      }.by(3)

      PromotionListserv.last(3).sort_by(&:id).each_with_index do |pl, index|
        expect(pl.promotion.content).to eql content
        expect(pl.listserv).to eql listservs[index]
      end
    end

    it 'adds the locations of the listservs to the content record' do
      locations = listservs.collect(&:locations).flatten
      subject
      expect(content.reload.locations).to include(*locations)
    end

    context "When some are external" do
      before do
        subset = listservs.sort_by(&:id).first(2)
        subset.each_with_index do |ls,i|
          ls.update! reverse_publish_email: "test#{i}@test.com"
        end
      end


      it 'should update sent_at with the current time', freeze_time: true do
        tm = Time.zone.now
        test_group = PromotionListserv.order("id asc").first(2)
        test_group.each do |pl|
          expect(pl.sent_at).to be_within(1.second).of tm
        end
      end

    end

    context 'Several are external listservs;' do
      before do
        6.times do
          listservs << FactoryGirl.create(:vc_listserv)
        end
      end

      it 'should send two emails (list, confirmation) for the vc_list', inline_jobs: true do
        expect{subject}.to change{ActionMailer::Base.deliveries.count}.by 2

        first = ActionMailer::Base.deliveries.first
        second = ActionMailer::Base.deliveries.second

        reverse_publish_emails = listservs.select(&:is_vc_list?).map(&:reverse_publish_email)
        expect(first.to).to include(*reverse_publish_emails)
        expect(second.to).to include(content.authoremail)
      end
    end

    context "When some are internally managed listservs" do
      let!(:internal) { FactoryGirl.create_list :subtext_listserv, 3 }
      before do
        internal.each {|i| listservs << i }
      end

      it 'creates a verified, matching ListservContent record for each listserv' do
        expect{subject}.to change{
          ListservContent.count
        }.by(internal.count)

        listserv_contents = ListservContent.last(internal.count)

        internal.each do |list|
          lc = listserv_contents.find{|i| i.listserv_id == list.id}
          expect(lc.attributes.symbolize_keys).to match hash_including({
            subject: content.title,
            listserv_id: list.id,
            content_id: content.id,
            user_id: content.created_by.id,
            sender_name: content.created_by.name,
            sender_email: content.created_by.email,
            body: content.sanitized_content,
            verified_at: an_instance_of(ActiveSupport::TimeWithZone)
          })
        end
      end

      it 'back references the listserv content to the promotion listserv' do
        subject
        listserv_contents = ListservContent.last(internal.count)
        promotion_listservs = PromotionListserv.last(internal.count)

        expect(listserv_contents.map(&:id)).to match_array(promotion_listservs.collect(&:listserv_content_id))
      end

      context 'when a listserv_content record already exists' do
        let(:listserv) { internal.first }
        let!(:previous_content) {
          FactoryGirl.create :listserv_content, :verified,
            listserv: listserv,
            content: content
        }
        context 'sent in a previous digest' do
          let!(:previous_digest) {
            FactoryGirl.create :listserv_digest,
              listserv: listserv,
              listserv_content_ids: [previous_content.id],
              sent_at: 1.day.ago
          }


          it 'creates a verified, matching ListservContent record for each listserv' do
            expect{subject}.to change{
              ListservContent.count
            }.by(internal.count)

            listserv_contents = ListservContent.last(internal.count)

            internal.each do |list|
              lc = listserv_contents.find{|i| i.listserv_id = list.id}
              expect(lc.attributes.symbolize_keys).to match hash_including({
                subject: content.title,
                listserv_id: list.id,
                content_id: content.id,
                user_id: content.created_by.id,
                sender_name: content.created_by.name,
                sender_email: content.created_by.email,
                body: content.sanitized_content,
                verified_at: an_instance_of(ActiveSupport::TimeWithZone)
              })
            end
          end
        end

        context 'not yet sent in a digest' do
          # previous digest, does not include listserv_content_id
          let!(:previous_digest) {
            FactoryGirl.create :listserv_digest,
              listserv: listserv,
              listserv_content_ids: [99],
              sent_at: 1.day.ago
          }

          it 'updates the existing listserv content record' do
            content.update! raw_content: '<p>New Content</p>', title: "New Title"
            expect{
              subject
              previous_content.reload
            }.to change{
              previous_content.subject
            }.to(content.title).and change{
              previous_content.body
            }.to(content.sanitized_content)
          end

          it 'creates a verified, matching ListservContent records for each other listserv' do
            expect{subject}.to change{
              ListservContent.count
            }.by(internal.count - 1)

            listserv_contents = ListservContent.last(internal.count - 1)

            internal.each do |list|
              lc = listserv_contents.find{|i| i.listserv_id = list.id}
              expect(lc.attributes.symbolize_keys).to match hash_including({
                subject: content.title,
                listserv_id: list.id,
                content_id: content.id,
                user_id: content.created_by.id,
                sender_name: content.created_by.name,
                sender_email: content.created_by.email,
                body: content.sanitized_content,
                verified_at: an_instance_of(ActiveSupport::TimeWithZone)
              })
            end
          end

          context 'with multiple previously created listserv_content records' do
            let!(:previous_content2) {
              FactoryGirl.create(:listserv_content,
                :verified, {
                  listserv: listserv,
                  content: content
                }
              )
            }

            it 'updates the last record' do
              content.update! raw_content: '<p>New Content</p>', title: "New Title"
              last_record = previous_content2
              expect{
                subject
                last_record.reload
              }.to change{
                last_record.subject
              }.to(content.title).and change{
                last_record.body
              }.to(content.sanitized_content)
            end

            context 'when the last one has been sent' do
              before do
                FactoryGirl.create(:listserv_digest,
                  listserv: listserv,
                  listserv_content_ids: [previous_content2.id],
                  sent_at: 1.day.ago
                )
              end

              it 'does not update the the other listservContent records' do
                content.update! raw_content: '<p>New Content</p>', title: "New Title"
                expect{
                  subject
                  previous_content.reload
                }.to_not change{
                  previous_content.subject
                }
              end

              it 'creates a new listserv_content record' do
                expect{ subject }.to change{
                  ListservContent.count
                }.by(internal.count)
              end

            end
          end
        end
      end

      it 'back references the subscription to the listserv_content' do
        subject
        subscriptions = Subscription.where(
          user_id: content.created_by
        )

        internal.each do |ls|
          subscription = subscriptions.find{|s| s.listserv == ls}

          lc = ListservContent.find_by listserv: ls
          expect(lc.subscription).to eql subscription
        end
      end

      context 'when not yet subscribed' do
        it 'subscribes the user to each listserv' do
          subject
          subscriptions = Subscription.where(
            user_id: content.created_by
          )

          internal.each do |ls|
            subscription = subscriptions.find{|s| s.listserv == ls}
            expect(subscription).to be_present
          end
        end

      end
    end
  end
end
