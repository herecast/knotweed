require 'rails_helper'

RSpec.describe VerifyAndUpdateListservContent do
  context 'Given a ListservContent model, and attributes hash' do
    let(:listserv_content) { FactoryGirl.create :listserv_content }
    let(:attributes) {
      {
        subject: "my new subject line",
        body: "I changed the body too.",
        verify_ip: '192.168.0.1'
      }
    }

    subject { described_class.call(listserv_content, attributes) }

    context 'When already verified' do
      before do
        listserv_content.update verified_at: Time.now
      end

      it "raises ListservExceptions::AlreadyVerified" do
        expect{ subject }.to raise_error(ListservExceptions::AlreadyVerified)
      end
    end

    it 'returns true' do
      expect(subject).to be true
    end

    it 'updates record' do
      subject
      listserv_content.reload
      expect(listserv_content.subject).to eql attributes[:subject]
      expect(listserv_content.body).to eql attributes[:body]
    end

    it 'sets #verified_at' do
      expect{ subject }.to change{
        listserv_content.reload.verified_at
      }.to instance_of(ActiveSupport::TimeWithZone)
    end

    it 'updates listserv content metric to verified' do
      listserv_content_metric = FactoryGirl.create :listserv_content_metric, listserv_content_id: listserv_content.id
        expect{ subject }.to change{
          listserv_content_metric.reload.verified
        }.to true
    end

    context 'validation errors' do
      before do
        allow(listserv_content).to receive(:valid?).and_return(false)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'without content_id' do
      before do
        attributes[:content_id] = nil
      end

      it 'sends no enhance confirmation email' do
        expect(NotificationService).to receive(:posting_confirmation)
        subject
      end
    end


    context 'When content_id included in attributes update' do
      before do
        @user = FactoryGirl.create :user
        @content = FactoryGirl.create :content, created_by: @user
        attributes[:content_id] = @content.id
      end

      it 'updates content reference' do
        subject
        expect(listserv_content.reload.content).to eql @content
      end

      it 'triggers confirmation email' do
        expect(NotificationService).to receive(:posting_confirmation).with(listserv_content, an_instance_of(String).or(be_nil))
        subject
      end

      it 'updates listserv content metric' do
        listserv_content_metric = FactoryGirl.create :listserv_content_metric, listserv_content_id: listserv_content.id
        attributes[:channel_type] = 'Event'
        subject
        listserv_content_metric.reload
        expect(listserv_content_metric.verified).to be true
        expect(listserv_content_metric.enhanced).to be true
        expect(listserv_content_metric.username).to eq listserv_content.content.created_by.name
        expect(listserv_content_metric.post_type).to eq 'Event'
      end

      context 'when user has temp_password set;' do
        before do
          @user.temp_password= "89r32jjkl2390"
          @user.save!
        end

        it 'clear temp_password on user' do
          expect{ subject }.to change{
            @user.reload.temp_password
          }.to nil
        end
      end

      context 'when no existing user reference' do
        before do
          listserv_content.update user: nil
        end

        it 'sets user_id to content\'s created_by' do
          expect{ subject }.to change{
            listserv_content.reload.user_id
          }.to @user.id
        end
      end

      context 'when content user does not match listserv content user' do
        before do
          listserv_content.update user: FactoryGirl.create(:user)
        end

        it "raises ContentOwnerMismatch" do
          expect{ subject }.to raise_error(ContentOwnerMismatch)
        end
      end
    end

    context "when no existing subscription" do
      before do
        if sub = listserv_content.subscription
          listserv_content.update! subscription_id: nil
          sub.destroy!
        end
      end

      it 'subscribes email to listserv' do
        subject
        listserv_content.reload
        expect(listserv_content.subscription.listserv).to eql listserv_content.listserv
        expect(listserv_content.subscription.email).to eql listserv_content.sender_email
      end

      it 'sets the subscription to confirmed status' do
        subject
        listserv_content.reload
        expect(listserv_content.subscription).to be_confirmed
      end

      it 'does not send subscription verification email' do
        expect(NotificationService).to_not receive(:subscription_verification)
        subject
      end

      it 'sets the subscription user' do
        subject
        listserv_content.reload
        expect(listserv_content.subscription.user).to eql listserv_content.user
      end
    end

    context 'when subscription exists' do
      let!(:subscription) { FactoryGirl.create(:subscription, listserv: listserv_content.listserv, user: nil, email: listserv_content.sender_email) }

      before do
        listserv_content.update subscription: subscription
      end

      it 'sets the subscription user to match' do
        subject
        listserv_content.reload
        expect(listserv_content.subscription.user).to eql listserv_content.user
      end

      context 'Subscription not previously confirmed' do
        before do
          subscription.update confirmed_at: nil
        end

        it 'sets confirmed_at' do
          expect{subject}.to change{
            subscription.reload.confirmed_at
          }.to instance_of(ActiveSupport::TimeWithZone)
        end
      end

      context 'Subscription was previously unsubscribed' do
        before do
          subscription.update unsubscribed_at: Time.now
        end

        it 'resubscribes' do
          expect{ subject }.to change{
            subscription.reload.unsubscribed_at
          }.to nil
        end

        it 'does not send subscription verification email' do
          expect(NotificationService).to_not receive(:subscription_verification)
          subject
        end
      end
    end

  end
end
