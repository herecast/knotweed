class KitchenSinkMailer < ActionMailer::Base
  require 'htmlcompressor'

  default from: 'null@null.disabled',
          to: 'null@null.disabled',
          subject: 'This is the subject'

  layout 'email'

  def show
    mail()
  end

  # TODO send to litmus
  # Default handler override
  # def self.deliver_mail(mail_instance)
  # Disable default delivery process.
  # It is handled by this mailer instance.
  # mail_instance
  # end

  # def deliver_mail(mail_instance)
  # unless @digest.mc_campaign_id?
  #   @digest.update_attribute :mc_campaign_id, campaign[:id]
  # end
  # BackgroundJob.perform_later(self.class.name, 'send_campaign', @digest)
  # end
end
