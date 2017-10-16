# == Schema Information
#
# Table name: content_metrics
#
#  id          :integer          not null, primary key
#  content_id  :integer
#  event_type  :string
#  user_id     :integer
#  user_agent  :string
#  user_ip     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  client_id   :string
#  location_id :integer
#

class ContentMetric < ActiveRecord::Base
  belongs_to :location#remove comment for Rails 5#, optional: true
  belongs_to :user#remove comment for Rails 5#, optional: true
  belongs_to :content
  belongs_to :organization#remove comment for Rails 5#, optional: true

  validates_presence_of :content_id

  before_create do
    self.organization = content.organization
  end
end
