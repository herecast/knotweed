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
#  cc_emails             :string
#  bcc_emails            :string
#  report_type           :string
#

class Report < ActiveRecord::Base
  include Auditable

  has_many :report_recipients
  has_many :report_params, dependent: :destroy
  has_many :report_jobs

  accepts_nested_attributes_for :report_params, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true

  validates_presence_of :report_type
end
