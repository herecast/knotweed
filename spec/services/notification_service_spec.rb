require 'spec_helper'

RSpec.describe NotificationService do
  subject { NotificationService }

  it { is_expected.to respond_to(:subscription_confirmation) }
  it { is_expected.to respond_to(:subscription_verification) }
  it { is_expected.to respond_to(:existing_subscription) }

  it { is_expected.to respond_to(:posting_verification) }

  it { is_expected.to respond_to(:subscriber_blacklisted) }

  describe "#subscription_confirmation" do
    let(:subscription) { FactoryGirl.create :subscription }
    it 'Delivers via activemailer delayed' do
      mail = double()
      expect(mail).to receive(:deliver_later)
      expect(ListservMailer).to receive(:subscription_confirmation).with(subscription).and_return(mail)

      NotificationService.subscription_confirmation(subscription)
    end
  end

  describe "#subscription_verification" do
    let(:subscription) { FactoryGirl.create :subscription }
    it 'Delivers via activemailer delayed' do
      mail = double()
      expect(mail).to receive(:deliver_later)
      expect(ListservMailer).to receive(:subscription_verification).with(subscription).and_return(mail)

      NotificationService.subscription_verification(subscription)
    end
  end

  describe "#existing_subscription" do
    let(:subscription) { FactoryGirl.create :subscription }
    it 'Delivers via activemailer delayed' do
      mail = double()
      expect(mail).to receive(:deliver_later)
      expect(ListservMailer).to receive(:existing_subscription).with(subscription).and_return(mail)

      NotificationService.existing_subscription(subscription)
    end
  end

  describe "#posting_verification" do
    let(:listserv_content) { FactoryGirl.create :listserv_content }
    it 'Delivers via activemailer delayed' do
      mail = double()
      expect(mail).to receive(:deliver_later)
      expect(ListservMailer).to receive(:posting_verification).with(listserv_content).and_return(mail)

      NotificationService.posting_verification(listserv_content)
    end
  end

  describe '#subscriber_blacklisted' do
    let(:subscription) { FactoryGirl.create :subscription }
    it 'Delivers vis activemailer delayed' do
      mail = double()
      expect(mail).to receive(:deliver_later)
      expect(ListservMailer).to receive(:subscriber_blacklisted).with(subscription).and_return(mail)

      NotificationService.subscriber_blacklisted(subscription)
    end
  end

end
