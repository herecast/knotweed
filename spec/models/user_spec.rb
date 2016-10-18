# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  default_repository_id  :integer
#  nda_agreed_at          :datetime
#  agreed_to_nda          :boolean          default(FALSE)
#  admin                  :boolean          default(FALSE)
#  contact_phone          :string(255)
#  contact_email          :string(255)
#  contact_url            :string(255)
#  location_id            :integer
#  test_group             :string(255)      default("consumer")
#  muted                  :boolean          default(FALSE)
#  authentication_token   :string(255)
#  avatar                 :string(255)
#  public_id              :string(255)
#  skip_analytics         :boolean          default(FALSE)
#  temp_password          :string(255)
#

require 'spec_helper'

describe User, :type => :model do
  it{ is_expected.to respond_to(:temp_password, :temp_password=) }

  before(:each) do
    location = FactoryGirl.create :location
    @attr = {
      :name => "Example User",
      :email => "user@example.com",
      :password => "changeme",
      :password_confirmation => "changeme",
      :location => location
    }
  end

  it "should create a new instance given a valid attribute" do
    User.create!(@attr)
  end

  it "should require an email address" do
    no_email_user = User.new(@attr.merge(:email => ""))
    expect(no_email_user).not_to be_valid
  end

  it "should accept valid email addresses" do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      valid_email_user = User.new(@attr.merge(:email => address))
      expect(valid_email_user).to be_valid
    end
  end

  it "should reject invalid email addresses" do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    addresses.each do |address|
      invalid_email_user = User.new(@attr.merge(:email => address))
      expect(invalid_email_user).not_to be_valid
    end
  end

  it "should reject duplicate email addresses" do
    User.create!(@attr)
    user_with_duplicate_email = User.new(@attr)
    expect(user_with_duplicate_email).not_to be_valid
  end

  it "should reject email addresses identical up to case" do
    upcased_email = @attr[:email].upcase
    User.create!(@attr.merge(:email => upcased_email))
    user_with_duplicate_email = User.new(@attr)
    expect(user_with_duplicate_email).not_to be_valid
  end

  describe "passwords" do

    before(:each) do
      @user = User.new(@attr)
    end

    it "should have a password attribute" do
      expect(@user).to respond_to(:password)
    end

    it "should have a password confirmation attribute" do
      expect(@user).to respond_to(:password_confirmation)
    end
  end

  describe "password validations" do

    it "should require a password" do
      expect(User.new(@attr.merge(:password => "", :password_confirmation => ""))).
        not_to be_valid
    end

    it "should require a matching password confirmation" do
      expect(User.new(@attr.merge(:password_confirmation => "invalid"))).
        not_to be_valid
    end

    it "should reject short passwords" do
      short = "a" * 5
      hash = @attr.merge(:password => short, :password_confirmation => short)
      expect(User.new(hash)).not_to be_valid
    end

  end

  describe "password encryption" do

    before(:each) do
      @user = User.create!(@attr)
    end

    it "should have an encrypted password attribute" do
      expect(@user).to respond_to(:encrypted_password)
    end

    it "should set the encrypted password attribute" do
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

  describe 'can_publish_news?' do
    before do
      @user = FactoryGirl.create :user
    end

    subject { @user.can_publish_news? }

    it 'should be false if the user can\'t manage any organizations' do
      expect(subject).to be_falsey
    end

    context 'with user associated with a non-news-publishing organization' do
      before do
        @org = FactoryGirl.create :organization, can_publish_news: false
        @user.add_role :manager, @org
      end

      it { is_expected.to be_falsey }
    end

    context 'with user associated with a news-publishing organization' do
      before do
        @org = FactoryGirl.create :organization, can_publish_news: true
        @user.add_role :manager, @org
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#managed_organizations' do
    before do
      @user = FactoryGirl.create :user
      @organization = FactoryGirl.create :organization
      @user.add_role(:manager, @organization)
    end

    it "returns managed organizations" do
      expect(@user.managed_organizations).to match_array [@organization]
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
          expect(BackgroundJob).to receive(:perform_later).with('MailchimpService','update_subscription', @sub)
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

end
