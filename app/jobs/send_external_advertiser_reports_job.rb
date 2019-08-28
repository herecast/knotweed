class SendExternalAdvertiserReportsJob < ApplicationJob
  def perform
    organization_ids = Content.ad_campaigns_for_reports.pluck(:organization_id).uniq

    organization_ids.each do |organization_id|
      organization = Organization.find(organization_id)

      PromotionsMailer.external_advertiser_report(
        organization: organization,
        campaigns: organization.contents.ad_campaigns_for_reports
      ).deliver_later
    end
  end
end