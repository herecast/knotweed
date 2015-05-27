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
#  organization_id        :integer
#  default_repository_id  :integer
#  nda_agreed_at          :datetime
#  agreed_to_nda          :boolean          default(FALSE)
#  admin                  :boolean          default(FALSE)
#  event_poster           :boolean          default(FALSE)
#  contact_phone          :string(255)
#  contact_email          :string(255)
#  contact_url            :string(255)
#  location_id            :integer
#  test_group             :string(255)
#  muted                  :boolean          default(FALSE)
#  discussion_listserve   :string(255)
#  view_style             :integer
#

class User < ActiveRecord::Base

  belongs_to :organization # for organization admin
  has_many :notifiers
  belongs_to :default_repository, class_name: "Repository"
  belongs_to :location

  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :role_ids, :as => :admin
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :organization_id, :role_ids,
    :default_repository_id, :location, :location_id
  
end
