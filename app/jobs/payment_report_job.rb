class PaymentReportJob < ApplicationJob

  def perform(report_job)
    payments = []
    report_job.report_job_recipients.each do |recip|
      report_payments = PaymentReportService.run_report(
        report_job.report.report_type, 
        report_job.report_params_hash(recip)
      )
      payments += report_payments
    end

    Payment.transaction do
      payments.each do |p|
        Payment.create!(p)
      end
      report_job.update report_sent_date: Time.current
    end
  end

end
