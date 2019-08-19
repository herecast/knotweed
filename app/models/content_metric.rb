# frozen_string_literal: true

# == Schema Information
#
# Table name: content_metrics
#
#  id                 :bigint(8)        not null, primary key
#  content_id         :integer
#  event_type         :string
#  user_id            :integer
#  user_agent         :string
#  user_ip            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  client_id          :string
#  location_id        :integer
#  organization_id    :integer
#  location_confirmed :boolean          default(FALSE)
#
# Indexes
#
#  index_content_metrics_on_client_id        (client_id)
#  index_content_metrics_on_content_id       (content_id)
#  index_content_metrics_on_created_at       (created_at)
#  index_content_metrics_on_event_type       (event_type)
#  index_content_metrics_on_location_id      (location_id)
#  index_content_metrics_on_organization_id  (organization_id)
#  index_content_metrics_on_user_id          (user_id)
#

class ContentMetric < ActiveRecord::Base
  belongs_to :location # remove comment for Rails 5#, optional: true
  belongs_to :user # remove comment for Rails 5#, optional: true
  belongs_to :content
  belongs_to :organization # remove comment for Rails 5#, optional: true

  validates_presence_of :content_id

  before_create do
    self.organization = content.organization
  end

  def self.views_by_user_and_period(period_start:, period_end:, user:)
    period_start = period_start.beginning_of_day
    period_end = period_end.end_of_day
    ContentMetric.where("event_type = 'impression'")
                 .where('content_metrics.created_at BETWEEN ? and ?', period_start, period_end)
                 .where('contents.created_by_id = ?', user)
                 .joins(:content, :organization)
                 .where('pay_for_content = true')
                 .count(:id)
  end
end
