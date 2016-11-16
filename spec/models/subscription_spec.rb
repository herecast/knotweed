# == Schema Information
#
# Table name: subscriptions
#
#  id                   :integer          not null, primary key
#  user_id              :integer
#  listserv_id          :integer
#  confirmed_at         :datetime
#  unsubscribed_at      :datetime
#  blacklist            :boolean          default(FALSE)
#  subscription_details :string
#  source               :string
#  email                :string           not null
#  confirmation_details :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  key                  :string           not null
#  name                 :string
#  confirm_ip           :string
#  email_type           :string           default("html")
#

require 'rails_helper'

RSpec.describe Subscription, type: :model do

  it { is_expected.to belong_to(:user)}
  it { is_expected.to belong_to(:listserv)}
  it { is_expected.to have_db_column(:name) }

  it { is_expected.to have_db_column(:confirm_ip).of_type(:string) }
  it { is_expected.to have_db_column(:email_type).of_type(:string) }
  it { is_expected.to have_db_column(:mc_unsubscribed_at).of_type(:datetime) }

  describe 'validation' do
    subject { FactoryGirl.build :subscription }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email)\
                          .scoped_to(:listserv_id)\
                          .case_insensitive }
    it { is_expected.to validate_presence_of(:listserv) }

    context 'when confirmed' do
      before do
        subject.confirmed_at = Time.current
        subject.confirm_ip = nil
      end

      it 'requires confirm_ip' do
        subject.valid?
        expect(subject.errors[:confirm_ip]).to include('can\'t be blank')
      end
    end
  end

  describe '#email' do
    context 'assigning' do
      it 'transforms to lowercase' do
        subject.email = "My@email.COM"
        expect(subject.email).to eql "my@email.com"
      end
    end
  end

  describe '#unsubscribed?' do
    it 'is alias for #unsubscribed_at?' do
      expect(subject).to receive(:unsubscribed?).and_return(true)
      val = subject.unsubscribed?
      expect(val).to be true
    end
  end

  describe '#confirmed?' do
    it 'is alias for #confirmed_at?' do
      expect(subject).to receive(:confirmed_at?).and_return(true)
      val = subject.confirmed?
      expect(val).to be true
    end
  end


  describe '#key' do
    subject { FactoryGirl.create :subscription }
    it 'is generated automatically' do
      random_key = SecureRandom.uuid
      allow(SecureRandom).to receive(:uuid).and_return(random_key)
      expect(subject.key).to eql random_key
    end
  end

  describe 'auto user detection' do
    context 'when no user connected' do
      let!(:subscription) { FactoryGirl.create :subscription, user: nil }
      context 'when user exists with matching email' do
        let!(:user) { FactoryGirl.create :user, email: subscription.email }

        it 'connects user on save' do
          subscription.save!
          expect(subscription.reload.user).to eql(user)
        end
      end
    end
  end

  describe '#subscriber_name' do
    context 'no user record' do
      let(:subscription) { Subscription.new name: "Mickey Mouse", user: nil }

      subject { subscription.subscriber_name }

      it "is equal to #name" do
        expect(subject).to eql subscription.name
      end
    end

    context 'user record' do
      let(:user) { FactoryGirl.create :user, name: 'Donald Duck' }
      let(:subscription) { Subscription.new name: "Mickey Mouse", user: user }

      subject { subscription.subscriber_name }

      it "is equal to #user.name" do
        expect(subject).to eql user.name
      end
    end
  end

end
