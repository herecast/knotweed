# == Schema Information
#
# Table name: listserv_content_metrics
#
#  id                   :integer          not null, primary key
#  listserv_content_id  :integer
#  email                :string
#  time_sent            :datetime
#  post_type            :string
#  username             :string
#  verified             :boolean
#  enhanced             :boolean
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  enhance_link_clicked :boolean
#  step_reached         :string
#

class ListservContentMetric < ActiveRecord::Base
  belongs_to :listserv_content
  validates_presence_of :listserv_content_id
end
