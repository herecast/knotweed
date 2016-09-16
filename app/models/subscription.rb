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
#  subscription_details :string(255)
#  source               :string(255)
#  email                :string(255)      not null
#  confirmation_details :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  key                  :string(255)      not null
#  name                 :string(255)
#  confirm_ip           :string(255)
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