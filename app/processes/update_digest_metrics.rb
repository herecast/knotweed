# frozen_string_literal: true

class UpdateDigestMetrics
  def self.call(*args)
    new(*args).call
  end

  def initialize(listserv_digest)
    @digest = listserv_digest
  end

  def call
    if @digest.mc_campaign_id
      @digest.update digest_report_attributes
    else
      raise 'The ListservDigest does not have a Mailchimp Campaign ID'
    end
  end

  def digest_report_attributes
    {
      emails_sent: _report[:emails_sent],
      opens_total: _report[:opens][:opens_total],
      link_clicks: promotion_clicks,
      last_mc_report: Time.current
    }
  end

  def promotion_clicks
    @digest.promotions.each_with_object({}) do |promotion, memo|
      clicks = clicks_for_promo(promotion)

      memo[promotion.promotable.redirect_url] = clicks if clicks
    end
  end

  def clicks_for_promo(promotion)
    record = _clicks_report[:urls_clicked].find do |url_info|
      url_info[:url].starts_with?(promotion.promotable.redirect_url)
    end

    record.try(:[], :total_clicks)
  end

  private

  def _report
    @report_data ||= MailchimpService.get_campaign_report @digest.mc_campaign_id
  end

  def _clicks_report
    @click_report_data ||= MailchimpService.get_campaign_clicks_report @digest.mc_campaign_id
  end
end
