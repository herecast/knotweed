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
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentMetric < ActiveRecord::Base
  validates_presence_of :content_id
end
