# == Schema Information
#
# Table name: content_metrics
#
#  id         :integer          not null, primary key
#  content_id :integer
#  event_type :string
#  user_id    :integer
#  user_agent :string
#  user_ip    :string
#  client_id  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentMetric < ActiveRecord::Base
  belongs_to :location#remove comment for Rails 5#, optional: true
  belongs_to :user#remove comment for Rails 5#, optional: true

  validates_presence_of :content_id
end
