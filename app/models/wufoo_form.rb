# == Schema Information
#
# Table name: wufoo_forms
#
#  id             :integer          not null, primary key
#  form_hash      :string(255)
#  email_field    :string(255)
#  name           :string(255)
#  call_to_action :text
#  controller     :string(255)
#  action         :string(255)
#  active         :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  page_url_field :string(255)
#

class WufooForm < ActiveRecord::Base
  attr_accessible :action, :active, :call_to_action, :controller, 
    :email_field, :page_url_field, :form_hash, :name, :consumer_app_ids
  has_and_belongs_to_many :consumer_apps

  validates_presence_of :controller, :form_hash, :call_to_action

  scope :active, where(active: true)

  after_validation :set_inactive_value_to_nil

  def set_inactive_value_to_nil
    if active == false
      self.active = nil
    end
  end
end