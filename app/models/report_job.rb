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

class ReportJob < ActiveRecord::Base
  include Auditable

  belongs_to :report
  has_many :report_job_params, as: :report_job_paramable, dependent: :destroy
  has_many :report_job_recipients, dependent: :destroy

  accepts_nested_attributes_for :report_job_params, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true

  # generated report params are a combination of the report job params
  # and the report_job_recipient_params attached to the currently active 
  # recipient
  def report_params_hash(recipient)
    rparams = {}
    report_job_params.each do |rp|
      rparams[rp.param_name] = rp.param_value
    end
    
    recipient.report_job_params.each do |recip_param|
      # recipient params override job params
      rparams[recip_param.param_name] = recip_param.param_value
    end

    # add user_id
    rparams["user_id"] = recipient.report_recipient.user_id
    rparams
  end

  # prepends recipient name to the report output_file_name
  def filename(recipient)
    user = recipient.report_recipient.user
    name = user.fullname.present? ? user.fullname : user.name
    "#{name.gsub(' ', '_')}_#{report.output_file_name}"
  end

  def report_job_args(recipient, is_review=true)
    {
      output_file_name: filename(recipient),
      run_type: is_review ? :review : :send,
      review_folder: report.repository_folder,
      overwrite: report.overwrite_files,
      report_params: report_params_hash(recipient),
      recipients: recipient.to_addresses,
      report_path: report.report_path,
      email_subject: report.email_subject,
      alert_recipients: report.alert_recipients.try(:split,',').try(:map, &:strip),
      cc_email: report.cc_email,
      bcc_email: report.bcc_email
    }.tap do |args|
      if is_review
        args[:output_formats] = report.output_formats_review
      else
        args[:output_formats] = report.output_formats_send
      end
    end
  end

  def run_report_job(is_review=true)
    report_job_recipients.each do |recip|
      JasperService.submit_job(report_job_args(recip, is_review))
    end

    if is_review
      update report_review_date: Time.zone.now
    else
      update report_sent_date: Time.zone.now
    end
  end

  def self.create_from_report!(report)
    report_job = ReportJob.new(report: report)

    report.report_params.where(report_param_type: :report).each do |rp|
      report_job.report_job_params << ReportJobParam.new(param_name: rp.param_name,
                                                         param_value: rp.param_value)
    end

    report.report_recipients.each do |rr|
      params = report.report_params.where(report_param_type: :recipient).map do |rp|
        ReportJobParam.new(param_name: rp.param_name, param_value: rp.param_value)
      end
      report_job.report_job_recipients << ReportJobRecipient.new(report_recipient: rr,
                                                                report_job_params: params)
    end

    report_job.save!
    report_job
  end
end
