# frozen_string_literal: true

class PublishersMailer < ApplicationMailer
  def publisher_agreement_confirmation(user)

    # in future, this will be changeable in Admin
    pdf_url = 'https://subtext-misc.s3.amazonaws.com/pdfs/Paid_Content_Addendum_20191001.pdf'
    pdf = open(pdf_url).read

    attachments['Publisher-Agreement-October-2019.pdf'] = pdf
    mail(to: user.email,
        from: 'Aileen from HereCast <ads@herecast.us>',
        subject: "Publisher Agreement Confirmation")
  end
end