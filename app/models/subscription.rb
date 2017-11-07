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
#  mc_unsubscribed_at   :datetime
#
# Indexes
#
#  index_subscriptions_on_listserv_id  (listserv_id)
#  index_subscriptions_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_7de388d95b  (listserv_id => listservs.id)
#  fk_rails_933bdff476  (user_id => users.id)
#

class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :listserv

  validates :email, presence: true,
    uniqueness: { scope: :listserv_id, case_sensitive: false }

  validates :listserv, presence: true
  validates :confirm_ip, presence: true, if: :confirmed?

  validates :key, presence: true, uniqueness: true
  after_initialize :generate_key, unless: :key

  before_save :detect_and_connect_user, unless: :user_id?

  scope :active, -> {
    where("confirmed_at IS NOT NULL").where(unsubscribed_at: nil)
  }

  def self.find(id)
    find_by!("#{table_name}.id = :id OR #{table_name}.key = :key", id: id.to_i, key: id.to_s)
  end

  def email=value
    super(value.try(:downcase))
  end

  def unsubscribed?
    unsubscribed_at?
  end

  def confirmed?
    confirmed_at?
  end

  def subscriber_name
    user.try(:name) || name
  end

  def subscribed?
    confirmed? && !unsubscribed?
  end

  protected

  def detect_and_connect_user
    usr = User.where(email: email).first
    if usr
      self.user = usr
    end
  end

  def generate_key
    self.key = SecureRandom.uuid
  end

  def cast_id_type(id)
  end
end
