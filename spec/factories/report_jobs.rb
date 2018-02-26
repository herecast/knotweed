# == Schema Information
#
# Table name: report_jobs
#
#  id                 :integer          not null, primary key
#  report_id          :integer
#  description        :text
#  report_review_date :datetime
#  report_sent_date   :datetime
#  created_by         :integer
#  updated_by         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_job do
    report
    description "MyText"
    report_review_date "2018-02-06 12:18:40"
    report_sent_date "2018-02-06 12:18:40"
  end
end
