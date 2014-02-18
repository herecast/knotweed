class JobMailer < ActionMailer::Base
  default from: "jobs@subtext.org"

  def error_email(record, error)
    @job = record.job
    @record = record
    @error = error
    mail(to: @job.notifyees.map(&:email), subject: "Error Running #{@job.class.name} #{@job.id}") do |format|
      format.text
    end
  end

end
