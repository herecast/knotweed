require 'rails_helper'

RSpec.describe ProcessReceivedEmailJob, type: :job do
  context 'given a persisted ReceivedEmail' do
    let(:email) { FactoryGirl.create :received_email }

    subject { ProcessReceivedEmailJob.new.perform(email) }

    context 'When from, and to fields are not yet present' do
      before do
        email.update to: nil, from: nil
      end

      it 'triggers #preprocess on email' do
        expect_any_instance_of(ReceivedEmail).to receive(:preprocess).and_return(nil)
        subject
      end
    end

    it 'updates #processed_at' do
      # disable preprocessing, not a real email
      allow_any_instance_of(ReceivedEmail).to receive(:preprocess).and_return(nil)

      expect{ subject }.to change{
        email.reload.processed_at
      }.from(nil).to(an_instance_of(ActiveSupport::TimeWithZone))
    end

    context 'When email is a subscribe_to_listserv purpose;' do
      before do
        # stub, we don't want to process email
        allow_any_instance_of(ReceivedEmail).to receive(:preprocess).and_return(nil)
        email.to = "subscribe.list@listserv.example"
        email.from = "some.user@example.org"
        email.save!
      end

      let!(:listserv) { FactoryGirl.create :subtext_listserv, subscribe_email: email.to }

      it 'triggers process: SubscribeToListserv' do
        expect(SubscribeToListserv).to receive(:call).with(listserv, {
          email: email.from,
          name: email.sender_name,
          source: "email"
        })
        subject
      end

      it 'sets result to "Subscription processed"' do
        expect{ subject }.to change{
          email.result
        }.to 'Subscription processed'
        subject
      end

      it 'sets record to returned subscription model' do
        expect{ subject }.to change{
          email.record
        }.to an_instance_of(Subscription)
        subject
      end

    end

    context 'When email has the purpose of unsubscribe_from_listserv' do
      before do
        # stub, we don't want to process email
        allow_any_instance_of(ReceivedEmail).to receive(:preprocess).and_return(nil)
        email.to = "unsubscribe.list@listserv.example"
        email.from = "some.user@example.org"
        email.save!
      end

      let!(:listserv) { FactoryGirl.create :subtext_listserv, unsubscribe_email: email.to }

      context 'when subscription exists;' do
        let(:subscription) { FactoryGirl.create :subscription, email: email.from, listserv: listserv }

        it 'sets subscription#unsubscribed_at' do
          expect{ subject }.to change{
            subscription.reload.unsubscribed_at
          }.from(nil)
        end
      end
    end

    context 'When email has the purpose of post_to_listserv' do
      before do
        # stub, we don't want to process email
        allow_any_instance_of(ReceivedEmail).to receive(:preprocess).and_return(nil)
        email.to = "post.to@listserv.example"
        email.from = "some.user@example.org"
        email.save!
      end

      let!(:listserv) { FactoryGirl.create :subtext_listserv, post_email: email.to }

      it 'triggers process: PostToListserv' do
        expect(PostToListserv).to receive(:call).with(listserv, email).and_return FactoryGirl.create :listserv_content
        subject
      end

      context 'when successful' do
        let(:listserv_content) { FactoryGirl.create :listserv_content, listserv: listserv }
        before do
          allow(PostToListserv).to receive(:call).and_return listserv_content
        end

        it 'adds reference to listserv content to email record' do
          expect{ subject }.to change{
            email.reload.record
          }.to an_instance_of(ListservContent)
        end

        it 'updates email record with result of "Posted to Listserv"' do
          expect{ subject }.to change{
            email.reload.result
          }.to "Posted to Listserv"
        end

        it 'creates ListservContentMetric' do
          expect{ subject }.to change{
            ListservContentMetric.count
          }.by 1
        end
      end

      context 'when listserv has blacklisted sender' do
        before do
          allow(PostToListserv).to receive(:call).and_raise(ListservExceptions::BlacklistedSender.new(listserv, email.from))
        end

        it 'sets result to blacklisted message' do
          expect{ subject }.to change{
            email.reload.result
          }.to "#{listserv.name} has blacklisted sender: #{email.from}"
        end
      end
    end
  end
end
