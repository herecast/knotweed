# == Schema Information
#
# Table name: report_job_recipients
#
#  id                     :integer          not null, primary key
#  report_job_id          :integer
#  report_recipient_id    :integer
#  created_by             :integer
#  updated_by             :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  report_review_date     :datetime
#  report_sent_date       :datetime
#  jasper_review_response :text
#  jasper_sent_response   :text
#  run_failed             :boolean          default(FALSE)
#

class ReportJobRecipient < ActiveRecord::Base
  include Auditable

  has_many :report_job_params, as: :report_job_paramable, dependent: :destroy
  belongs_to :report_job
  belongs_to :report_recipient

  validates_presence_of :report_recipient
  validates_presence_of :report_job

  accepts_nested_attributes_for :report_job_params, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true
  
  def to_addresses
    if report_recipient.alternative_emails.present?
      report_recipient.alternative_emails.split(',').map(&:strip)
    else
      [report_recipient.user.email]
    end
  end
end
