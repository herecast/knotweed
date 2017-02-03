class JobMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.batch_jobs

  def error_email(record, error)
    @job = record.job
    @record = record
    @error = error
    mail(to: @job.notifyees.map(&:email).uniq, subject: "#{default_url_options[:host]} - Error Running #{@job.class.name} #{@job.id}") do |format|
      format.text
    end
  end

  def file_ready(record)
    @job = record.job
    @record = record
    mail(to: @job.notifyees.map(&:email).uniq, subject: "#{default_url_options[:host]} - Archive File ready for #{@job.class.name} #{@job.id}") do |format|
      format.html
    end
  end
end
