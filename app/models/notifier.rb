# == Schema Information
#
# Table name: notifiers
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  notifyable_id   :integer
#  notifyable_type :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Notifier < ActiveRecord::Base
  belongs_to :notifyable, polymorphic: true
  belongs_to :user

  validates_presence_of :user_id
end
