# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                               :bigint(8)        not null, primary key
#  email                            :string(255)      default(""), not null
#  encrypted_password               :string(255)      default(""), not null
#  reset_password_token             :string(255)
#  reset_password_sent_at           :datetime
#  remember_created_at              :datetime
#  sign_in_count                    :bigint(8)        default(0)
#  current_sign_in_at               :datetime
#  last_sign_in_at                  :datetime
#  current_sign_in_ip               :string(255)
#  last_sign_in_ip                  :string(255)
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  name                             :string(255)
#  confirmation_token               :string(255)
#  confirmed_at                     :datetime
#  confirmation_sent_at             :datetime
#  unconfirmed_email                :string(255)
#  contact_phone                    :string(255)
#  contact_email                    :string(255)
#  location_id                      :bigint(8)
#  authentication_token             :string(255)
#  avatar                           :string(255)
#  public_id                        :string(255)
#  skip_analytics                   :boolean          default(FALSE)
#  archived                         :boolean          default(FALSE)
#  source                           :string
#  receive_comment_alerts           :boolean          default(TRUE)
#  location_confirmed               :boolean          default(FALSE)
#  fullname                         :string
#  nickname                         :string
#  epayment                         :boolean          default(FALSE)
#  w9                               :boolean          default(FALSE)
#  has_had_bookmarks                :boolean          default(FALSE)
#  mc_segment_id                    :string
#  first_name                       :string
#  last_name                        :string
#  feed_card_size                   :string
#  publisher_agreement_confirmed    :boolean          default(FALSE)
#  publisher_agreement_confirmed_at :datetime
#  publisher_agreement_version      :string
#  handle                           :string
#  mc_followers_segment_id          :string
#  email_is_public                  :boolean          default(FALSE)
#  background_image                 :string
#  description                      :string
#  website                          :string
#  phone                            :string
#
# Indexes
#
#  idx_16858_index_users_on_email                 (email) UNIQUE
#  idx_16858_index_users_on_public_id             (public_id) UNIQUE
#  idx_16858_index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

require 'spec_helper'

describe User, type: :model do
  it { is_expected.to have_db_column(:location_confirmed).of_type(:boolean) }

  before(:each) do
    location = FactoryGirl.create :location
    @attr = {
      name: 'Example User',
      email: 'user@example.com',
      password: 'changeme',
      password_confirmation: 'changeme',
      location: location
    }
  end

  it 'should create a new instance given a valid attribute' do
    expect { FactoryGirl.create :user, @attr }.to change { User.count }.by 1
  end

  it 'should require an email address' do
    no_email_user = FactoryGirl.build :user, @attr.merge(email: '')
    expect(no_email_user).not_to be_valid
  end

  it 'should accept valid email addresses' do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      valid_email_user = FactoryGirl.build :user, @attr.merge(email: address)
      expect(valid_email_user).to be_valid
    end
  end

  it 'should reject invalid email addresses' do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    addresses.each do |address|
      invalid_email_user = FactoryGirl.build :user, @attr.merge(email: address)
      expect(invalid_email_user).not_to be_valid
    end
  end

  it 'should reject duplicate email addresses' do
    FactoryGirl.create :user, @attr
    user_with_duplicate_email = FactoryGirl.build :user, @attr
    expect(user_with_duplicate_email).not_to be_valid
  end

  it 'should reject email addresses identical up to case' do
    upcased_email = @attr[:email].upcase
    FactoryGirl.create :user, @attr.merge(email: upcased_email)
    user_with_duplicate_email = FactoryGirl.build :user, @attr
    expect(user_with_duplicate_email).not_to be_valid
  end

  describe 'passwords' do
    before(:each) do
      @user = FactoryGirl.build :user, @attr
    end

    it 'should have a password attribute' do
      expect(@user).to respond_to(:password)
    end

    it 'should have a password confirmation attribute' do
      expect(@user).to respond_to(:password_confirmation)
    end
  end

  describe 'password validations' do
    it 'should require a password' do
      expect(FactoryGirl.build(:user, @attr.merge(password: '', password_confirmation: '')))
        .not_to be_valid
    end

    it 'should require a matching password confirmation' do
      expect(FactoryGirl.build(:user, @attr.merge(password_confirmation: 'invalid')))
        .not_to be_valid
    end

    it 'should reject short passwords' do
      short = 'a' * 5
      hash = @attr.merge(password: short, password_confirmation: short)
      expect(FactoryGirl.build(:user, hash)).not_to be_valid
    end
  end

  describe 'password encryption' do
    before(:each) do
      @user = FactoryGirl.create :user, @attr
    end

    it 'should have an encrypted password attribute' do
      expect(@user).to respond_to(:encrypted_password)
    end

    it 'should set the encrypted password attribute' do
      expect(@user.encrypted_password).not_to be_blank
    end
  end

  describe 'required fields' do
    before do
      @user = FactoryGirl.build :user, location: nil
    end
    subject { @user }
    it { is_expected.not_to be_valid }
  end

  context 'do not allow duplicate public ids' do
    before do
      name = 'montegate'
      @user = FactoryGirl.create :user, public_id: name
      @user2 = FactoryGirl.build :user, public_id: name
    end

    subject { @user2 }

    it do
      is_expected.not_to be_valid
      expect(@user2.errors.added?(:public_id, :taken)).to be_truthy
    end
  end

  describe 'subscription updates' do
    before do
      @user = FactoryGirl.create :user
      @new_location = FactoryGirl.create :location
    end

    context 'when user has subscriptions, and location is updated' do
      context 'when listserv is setup to sync with mailchimp' do
        before do
          @listserv = FactoryGirl.create :listserv, mc_list_id: '123', mc_group_name: 'my_group'
          @sub = FactoryGirl.create :subscription, user: @user, listserv: @listserv
        end

        it 'backgrounds a MailchimpService.update_subscription for each subscription' do
          expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'update_subscription', @sub)
          @user.location = @new_location
          @user.save!
        end
      end

      context 'when listserv is not setup to sync with mailchimp' do
        before do
          @listserv = FactoryGirl.create :listserv, mc_list_id: nil, mc_group_name: nil
          @sub = FactoryGirl.create :subscription, user: @user, listserv: @listserv
        end

        it 'does not trigger Mailchimpservice.update_subscription' do
          expect(BackgroundJob).to_not receive(:perform_later).with('MailchimpService', 'update_subscription', @sub)
          @user.location = @new_location
          @user.save!
        end
      end
    end
    context 'when user has subscriptions, but'
  end

  describe 'Updating content relevant attrs triggers a reindex of linked content' do
    let(:location) { FactoryGirl.create :location }
    let(:user) { FactoryGirl.create :user }

    User::CONTENT_RELEVANT_ATTRS.each do |attr|
      if attr == 'location_id'
        subject { user.update_attribute(:location_id, location.id) }

        it 'triggers reindex' do
          expect { subject }.to have_enqueued_job(
            ReindexAssociatedContentJob
          ).with(user)
        end
      else
        describe "changing #{attr}" do
          subject { user.update_attribute(attr.to_sym, 'new value') }

          it 'triggers reindex' do
            expect { subject }.to have_enqueued_job(
              ReindexAssociatedContentJob
            ).with(user)
          end
        end
      end
    end

    describe 'changing a non-dependent attribute' do
      subject { user.update_attribute(:fullname, 'Robert Paulson') }
      it 'does not trigger reindex' do
        expect { subject }.to_not have_enqueued_job(
          ReindexAssociatedContentJob
        )
      end
    end
  end

  describe '#active_for_authentication?' do
    subject { user.active_for_authentication? }

    context 'for a normal user' do
      let(:user) { FactoryGirl.create :user, archived: false }

      it 'should return true' do
        expect(subject).to be true
      end
    end

    context 'for an archived user' do
      let(:user) { FactoryGirl.create :user, archived: true }
      it 'should return false' do
        expect(subject).to be false
      end
    end
  end

  describe '#inactive_message' do
    subject { user.inactive_message }
    let(:user1) { FactoryGirl.create :user, archived: false }
    let(:user2) { FactoryGirl.create :user, archived: true }

    it 'should be different if the user is archived' do
      expect(user1.inactive_message).to_not eq user2.inactive_message
    end
  end

  describe '#location_id=' do
    let(:location) { FactoryGirl.create :location }

    context 'given a location id' do
      it 'sets the correct location' do
        subject.location_id = location.id
        expect(subject.location).to eq location
      end
    end

    context 'given a location slug' do
      it 'sets the correct location' do
        subject.location_id = location.slug
        expect(subject.location).to eq location
      end
    end

    describe '.from_facebook_oauth' do
      let(:facebook_response) do
        {
          email: 'facebook_user@mail.com',
          name: 'John Smith',
          verified: true,
          age_range: { min: 21 },
          timezone: -6,
          gender: 'male',
          id: '1234567',
          provider: 'facebook',
          extra_info: { verified: true,
                        age_range: { min: 21 },
                        time_zone: -6,
                        gender: 'male' }
        }
      end

      subject { User.from_facebook_auth(facebook_response) }

      context 'when the user already exists' do
        let!(:existing_facebook_user) { FactoryGirl.create :user }

        it 'returns the correct user' do
          auth = facebook_response.merge(email: existing_facebook_user.email)
          expect(User.from_facebook_oauth(auth)).to eq existing_facebook_user
        end

        context 'when the user has not logged in with facebook before' do
          let!(:existing_user) { FactoryGirl.create :user }
          before do
            @auth = facebook_response.merge(email: existing_user.email)
          end

          it 'returns the correct user' do
            expect(User.from_facebook_oauth(@auth)).to eq existing_user
          end

          it 'creates a SocialLogin record for the user' do
            user = User.from_facebook_oauth(@auth)
            expect(user.social_logins.first).to_not be_nil
          end

          it 'sets the correct fields on the SocialLogin record' do
            user = User.from_facebook_oauth(@auth)
            social_login = user.social_logins.first
            expect(social_login.provider).to eq facebook_response[:provider]
            expect(social_login.uid).to eq facebook_response[:id]
            expect(social_login.uid).to eq facebook_response[:id]
            # extra_info
            expect(social_login.extra_info).to eq facebook_response[:extra_info].deep_stringify_keys
          end
        end
      end

      context 'when the user does not have an existing account' do
        let!(:location) { FactoryGirl.create :location }
        let(:reg_attributes) { { location: location, handle: 'handle' } }

        it 'creates a new user account' do
          expect { User.from_facebook_oauth(facebook_response, reg_attributes) }.to change { User.count }.by(1)
        end

        it 'sets the correct info for the new user' do
          user = User.from_facebook_oauth(facebook_response, reg_attributes)
          expect(user.name).to eq facebook_response[:name]
          expect(user.email).to eq facebook_response[:email]
          expect(user.location).to eq location
        end

        it 'confirms the new users account' do
          user = User.from_facebook_oauth(facebook_response, reg_attributes)
          expect(user.confirmed?).to eq true
        end
      end
    end
  end

  describe "validations" do
    describe "feed_card_size" do
      context "when feed_card_size is not from options list" do
        subject { FactoryGirl.build(:user, feed_card_size: 'bad-option') }

        it "is not valid" do
          expect(subject).not_to be_valid
        end
      end

      context "when feed_card_size is from options list" do
        let(:size_option) { User::FEED_CARD_SIZE_OPTIONS.first }

        subject { FactoryGirl.build(:user, feed_card_size: size_option) }

        it "is valid" do
          expect(subject).to be_valid
        end
      end
    end

    describe "handle" do
      before do
        @handle = 'Jabba'
        @initial_user = FactoryGirl.create :user,
          handle: @handle
      end

      subject { FactoryGirl.build(:user, handle: @handle.downcase) }

      it "ignores case for uniqueness on handles" do
        expect(subject).to_not be_valid
      end
    end
  end
end
