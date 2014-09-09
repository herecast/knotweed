class WufooForm < ActiveRecord::Base
  attr_accessible :action, :active, :call_to_action, :controller, :email_field, :form_hash, :name

  validates_presence_of :controller, :form_hash, :call_to_action

  scope :active, where(active: true)

  after_validation :set_inactive_value_to_nil

  def set_inactive_value_to_nil
    if active == false
      self.active = nil
    end
  end
end
