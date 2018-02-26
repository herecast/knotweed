# == Schema Information
#
# Table name: reports
#
#  id                    :integer          not null, primary key
#  title                 :string
#  report_path           :string
#  output_formats_review :string
#  output_formats_send   :string
#  output_file_name      :string
#  repository_folder     :string
#  overwrite_files       :boolean          default(FALSE)
#  notes                 :text
#  created_by            :integer
#  updated_by            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  email_subject         :string
#  alert_recipients      :string
#  cc_email              :string
#  bcc_email             :string
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report do
    title "Report Titled The Most Important Report"
    report_path "/Reports/Bloggers/Blogger_Promoter_Payment_Report"
    output_formats_review "PDF"
    output_formats_send "PDF,HTML"
    output_file_name "test_report"
    repository_folder "/Reports/Bloggers/To_Review"
    overwrite_files false
    notes "misc subtext notes"
  end
end
