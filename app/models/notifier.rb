class Notifier < ActiveRecord::Base
  belongs_to :notifyable, polymorphic: true
  belongs_to :user

  attr_accessible :notifyable_id, :notifyable_type, :user_id

  validates_presence_of :user_id
end
