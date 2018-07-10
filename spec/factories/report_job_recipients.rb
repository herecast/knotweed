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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_job_recipient do
    report_job
    report_recipient
  end
end
