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
#  temp_password          :string
#  archived               :boolean          default(FALSE)
#  source                 :string
#  receive_comment_alerts :boolean          default(TRUE)
#  location_confirmed     :boolean          default(FALSE)
#
# Indexes
#
#  idx_16858_index_users_on_email                 (email) UNIQUE
#  idx_16858_index_users_on_public_id             (public_id) UNIQUE
#  idx_16858_index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ActiveRecord::Base

  has_many :notifiers
  has_many :subscriptions
  has_many :social_logins
  belongs_to :default_repository, class_name: "Repository"
  belongs_to :location
  mount_uploader :avatar, ImageUploader
  skip_callback :commit, :after, :remove_previously_stored_avatar,
                                 :remove_avatar!

  accepts_nested_attributes_for :subscriptions

  before_save :ensure_authentication_token

  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  validates_presence_of :location
  validates :public_id, uniqueness: true, allow_blank: true
  validates :avatar, :image_minimum_size => true

  after_update :update_subscriptions_locations

  ransacker :social_login

  def managed_organization_id; Organization.with_role(:manager, self).first.try(:id); end
  def is_organization_manager?; managed_organization_id.present?; end

  default_scope { order('id ASC') }

  def managed_organizations
    Organization.with_role(:manager, self)
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def reset_authentication_token
    self.authentication_token = generate_authentication_token
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

  def ability
      @ability ||= Ability.new(self)
  end

  # computed property that checks if the user has permission to manage
  # any organizations that have can_publish_news=true
  def can_publish_news?
    Organization.accessible_by(ability, :manage).where(can_publish_news: true).count > 0
  end

  attr_accessor :reset_password_return_url
  # http://www.rubydoc.info/github/plataformatec/devise/Devise/Models/Recoverable/ClassMethods#send_reset_password_instructions-instance_method
  def self.send_reset_password_instructions(attributes)
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes.except(:return_url), :not_found)
    if attributes[:return_url].present?
      recoverable.reset_password_return_url = attributes[:return_url]
    end
    recoverable.send_reset_password_instructions if recoverable.persisted?
    recoverable
  end

  def subscribed_listserv_ids
    self.subscriptions.map(&:listserv_id)
  end

  def active_listserv_subscription_ids
    self.subscriptions.where(unsubscribed_at: nil).map(&:listserv_id)
  end

  def update_subscriptions_locations
    if self.location_id_changed? && self.subscriptions.present?
      self.subscriptions.each do |sub|
        BackgroundJob.perform_later('MailchimpService', 'update_subscription', sub) if sub.listserv.try(:mc_sync?)
      end
    end
  end

  def unconfirmed_subscriptions?
    self.subscriptions.any? { |sub| sub.confirmed_at == nil }
  end

  def unconfirmed_subscriptions
    self.subscriptions.where(confirmed_at: nil)
  end

  def confirmed?
    self.confirmed_at != nil
  end

  # http://www.rubydoc.info/github/plataformatec/devise/master/Devise/Models/Authenticatable
  # http://stackoverflow.com/questions/6004216/devise-how-do-i-forbid-certain-users-from-signing-in
  def active_for_authentication?
    super && !archived?
  end

  def inactive_message
    archived? ? "The user account #{email} has been deactivated." : super
  end

  def location_id=lid
    unless lid.nil?
      loc=Location.find_by_slug_or_id(lid)
      super loc.id
    else
      super lid
    end
  end

  def self.from_facebook_oauth(auth, registration_attributes = {})
    extra_info = {}
    user = User.find_by_email(auth[:email])
    if user.nil?
      user = User.new({
        email: auth[:email],
        password: Devise.friendly_token[0,20],
        name: auth[:name],
        nda_agreed_at: Time.zone.now,
        agreed_to_nda: true
      }.merge(registration_attributes))

      if user.valid?
        user.skip_confirmation!
        SocialLogin.create(provider: auth[:provider], uid: auth[:id], extra_info: auth[:extra_info], user: user)
      end
      user
    else
      social_login = SocialLogin.find_or_create_by(user_id: user.id, provider: auth[:provider], uid: auth[:id])
      #this should capture any updates the user makes to their additional info.
      social_login.update_attributes(extra_info: auth[:extra_info])
      user
    end
  end

  def unique_roles
    roles.map{ |r| r.pretty_name }.uniq
  end

  private

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end
end
