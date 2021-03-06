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

class User < ActiveRecord::Base
  has_many :subscriptions
  has_many :social_logins
  has_many :likes
  has_many :contents, foreign_key: 'created_by_id'
  has_many :payments, foreign_key: 'paid_to_id'

  has_many :caster_follows

  has_many :caster_hides
  has_many :caster_hiders, class_name: 'CasterHide', foreign_key: 'caster_id'

  has_one :organization

  belongs_to :location
  mount_uploader :avatar, ImageUploader
  mount_uploader :background_image, ImageUploader
  skip_callback :commit, :after, :remove_previously_stored_avatar,
                :remove_avatar!, raise: false

  accepts_nested_attributes_for :subscriptions

  before_save :ensure_authentication_token

  rolify

  devise :database_authenticatable,
         :registerable,
         :confirmable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  validates_presence_of :location, :handle
  validates :public_id, uniqueness: true, allow_blank: true
  validates :avatar, image_minimum_size: true

  validates_uniqueness_of :handle, case_sensitive: false

  FEED_CARD_SIZE_OPTIONS = ['fullsize', 'midsize', 'compact']
  validates :feed_card_size, inclusion: { in: FEED_CARD_SIZE_OPTIONS, message: 'no such feed card size' }, allow_nil: true

  after_commit :update_subscriptions_locations,
               :trigger_content_reindex_if_content_relevant_attrs_changed,
               on: :update

  ransacker :social_login

  CONTENT_RELEVANT_ATTRS = [
    'avatar',
    'name',
    'handle',
    'description',
    'email_is_public',
    'location_id'
  ]

  default_scope { order('id ASC') }

  scope :sales_agents, -> { joins(:roles).where(roles: { name: 'sales agent' }) }
  scope :promoters, -> { joins(:roles).where(roles: { name: 'promoter' }) }
  scope :with_roles, -> { where('(select count(user_id) from users_roles where user_id=users.id) > 0').includes(:roles) }
  scope :not_archived, -> { where(archived: [false, nil]) }

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

  def active_listserv_subscription_ids
    subscriptions.where(unsubscribed_at: nil).map(&:listserv_id)
  end

  def update_subscriptions_locations
    if previous_changes.key?(:location_id) && subscriptions.present?
      subscriptions.each do |sub|
        BackgroundJob.perform_later('MailchimpService', 'update_subscription', sub) if sub.listserv.try(:mc_sync?)
      end
    end
  end

  def unconfirmed_subscriptions?
    subscriptions.any? { |sub| sub.confirmed_at.nil? }
  end

  def unconfirmed_subscriptions
    subscriptions.where(confirmed_at: nil)
  end

  def confirmed?
    confirmed_at != nil
  end

  # http://www.rubydoc.info/github/plataformatec/devise/master/Devise/Models/Authenticatable
  # http://stackoverflow.com/questions/6004216/devise-how-do-i-forbid-certain-users-from-signing-in
  def active_for_authentication?
    super && !archived?
  end

  def inactive_message
    archived? ? "The user account #{email} has been deactivated." : super
  end

  def location_id=(lid)
    if lid.nil?
      super lid
    else
      loc = Location.find_by_slug_or_id(lid)
      super loc.id
    end
  end

  def self.from_facebook_oauth(auth, registration_attributes = {})
    extra_info = {}
    user = User.find_by_email(auth[:email])
    if user.nil?
      user = User.new({
        email: auth[:email],
        password: Devise.friendly_token[0, 20],
        name: auth[:name],
        handle: registration_attributes[:handle]
      }.merge(registration_attributes))

      if user.valid?
        user.skip_confirmation!
        SocialLogin.create(provider: auth[:provider], uid: auth[:id], extra_info: auth[:extra_info], user: user)
      end
      user
    else
      social_login = SocialLogin.find_or_create_by(user_id: user.id, provider: auth[:provider], uid: auth[:id])
      # this should capture any updates the user makes to their additional info.
      social_login.update_attributes(extra_info: auth[:extra_info])
      user
    end
  end

  def caster
    Caster.find(id)
  end

  def active_follower_count
    caster.active_follower_count
  end

  def name_with_email
    "#{name} (#{email})"
  end

  def new_user_mc_segment_string
    "New User ID: #{id}"
  end

  def blocked_caster_ids
    caster_hides.active.pluck(:caster_id)
  end

  def counted_posts
    contents
      .not_removed
      .where('pubdate IS NOT NULL and pubdate < ?', Time.current)
      .where("channel_type != 'Comment' OR channel_type IS NULL")
      .where('content_category != ?', 'campaign')
      .where('biz_feed_public = true OR biz_feed_public IS NULL')
  end

  def total_view_count
    counted_posts.sum(:view_count).to_i
  end

  def post_count
    counted_posts.count
  end

  def total_like_count
    content_ids = contents.pluck(:id)
    Like.where(content_id: content_ids).count
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end

  def trigger_content_reindex_if_content_relevant_attrs_changed
    if (previous_changes.keys & CONTENT_RELEVANT_ATTRS).present?
      ReindexAssociatedContentJob.perform_later self
    end
  end
end
