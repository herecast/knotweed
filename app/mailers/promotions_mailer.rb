# frozen_string_literal: true

class PromotionsMailer < ApplicationMailer
  def external_advertiser_report(organization:, campaigns:)
    @organization = organization
    @campaigns = campaigns
    default_email = 'ads@herecast.us'

    pdf_packet = Promotions::BuildExternalAdvertiserReport.call(
      organization: @organization,
      campaigns: @campaigns
    )

    attachments[pdf_packet[:name]] = pdf_packet[:pdf]
    mail(to: @organization.ad_contact_email || default_email,
        from: 'Aileen from HereCast <ads@herecast.us>',
        subject: "HereCast Ad Report - #{@organization.name}")
  end
end