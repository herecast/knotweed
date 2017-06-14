require 'rails_helper'

RSpec.describe SubscribeToListservSilently do
  context 'Given a listserv and user' do
    let!(:listserv) { FactoryGirl.create :listserv, mc_list_id: '123', mc_group_name: 'blah' }
    let(:user) { FactoryGirl.create :user }
    let(:confirm_ip) { '127.0.0.1' }

    subject { SubscribeToListservSilently.call(listserv, user, confirm_ip) }

    it 'creates a subscription' do
      subscription = subject
      expect(subscription.valid?).to be true
      expect(subscription.persisted?).to be true
      expect(subscription.listserv).to eql listserv
      expect(subscription.email).to eql user.email
      expect(subscription.name).to eql user.name
      expect(subscription.source).to eql 'knotweed'
    end

    it 'backgrounds MailchimpService.subscribe' do
      expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'subscribe', an_instance_of(Subscription))
      subject
    end
    
    context 'when existing subscription' do
      let!(:existing) { Subscription.create!(listserv: listserv,
                                            email: user.email) }

      it 'returns the same subscription model' do
        subscription = subject
        expect(subscription.id).to eql existing.id
      end
      
      it 'backgrounds MailchimpService.subscribe' do
        expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'subscribe', an_instance_of(Subscription))
        subject
      end

      context 'when not confirmed' do
        before do
          existing.update! confirmed_at: nil
        end
        
        it 'confirms the subscription' do
          subscription = subject
          expect(subscription.confirmed_at).not_to be nil
        end
      
        it 'backgrounds MailchimpService.subscribe' do
          expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'subscribe', an_instance_of(Subscription))
          subject
        end
      end

      context 'when previosuly unsubscribed' do
        before do
          existing.update_attribute(:unsubscribed_at, Time.zone.now)
        end

        it 'changes unsubscribed status to subscribed' do
          expect{
            subject
          }.to change{
            existing.reload.unsubscribed?
          }.from(true).to(false)
        end

        it 'backgrounds MailchimpService.subscribe' do
          expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'subscribe', an_instance_of(Subscription))
          subject
        end
      end
    end

  end

end
