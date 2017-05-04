class StreamlinedRegistrationMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  include Devise::Mailers::Helpers
  default template_path: 'devise/mailer'

  def confirmation_instructions(record, token, opts={})
    opts[:template_name] = "streamlined_confirmation_instructions"
    @password = opts[:password]
    @first_name = record.name.split(" ").first.capitalize
    opts[:subject] = "Real Quick - Confirm Your DailyUV Account"
    headers['X-PM-TrackOpens'] = 'true'
    headers['X-PM-TrackLinks'] = 'true'
    super
  end
end
