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
#  enhance_link_clicked :boolean          default(FALSE)
#  step_reached         :string
#
# Indexes
#
#  index_listserv_content_metrics_on_listserv_content_id  (listserv_content_id)
#

class ListservContentMetric < ActiveRecord::Base
  belongs_to :listserv_content
  validates_presence_of :listserv_content_id
end
