# frozen_string_literal: true

module SubtextAdService
  extend self

  # creates ad record on Subtext ad service
  def create(campaign)
    response = HTTParty.post("#{config[:host]}/campaigns",
                  headers: headers,
                  body: campaign_params(campaign).to_json)
    campaign.update ad_service_id: response['_id']
    campaign.organization.update ad_service_id: response['client'] unless campaign.organization.ad_service_id.present?
  end

  # updates ad record
  def update(campaign)
    response = HTTParty.put("#{config[:host]}/campaigns/#{campaign.ad_service_id}",
                  headers: headers,
                  body: campaign_params(campaign).to_json)
  end

  # adds a new creative to an existing ad
  def add_creative(creative)
    response = HTTParty.post("#{config[:host]}/creatives",
                  headers: headers,
                  body: creative_params(creative).to_json)
    creative.update ad_service_id: response['_id']
  end

  def update_creative(creative)
    response = HTTParty.put("#{config[:host]}/creatives/#{creative.ad_service_id}",
                  headers: headers,
                  body: creative_params(creative).to_json)
  end

  private

  def campaign_params(campaign)
    params = {
      title: campaign.title,
      promotionType: campaign.ad_promotion_type,
      campaignStart: campaign.ad_campaign_start,
      campaignEnd: campaign.ad_campaign_end,
      maxImpressions: campaign.ad_max_impressions,
      invoicedAmount: campaign.ad_invoiced_amount
    }

    client = campaign.organization
    # if client already exists on subtext ad service, use ID
    if client.ad_service_id.present?
      params[:client] = client.ad_service_id
    else # otherwise create a new one
      params[:clientAttributes] = {
        name: campaign.organization.name,
        adContactNickname: campaign.organization.ad_contact_nickname,
        adContactFullname: campaign.organization.ad_contact_fullname
      }
    end
    params
  end

  def creative_params(creative)
    params = {
      redirectUrl: creative.redirect_url,
      imageUrl: creative.banner_image.url,
      description: creative.promotion.description,
      creativeStart: creative.campaign_start,
      creativeEnd: creative.campaign_end,
      promotionType: creative.promotion_type,
      maxImpressions: creative.max_impressions,
      locationId: creative.location_id,
      campaign: creative.promotion.content.ad_service_id # looking forward to getting rid of this model structure...
    }
  end

  def config
    {
      public_key: Figaro.env.subtext_ad_service_key,
      secret: Figaro.env.subtext_ad_service_secret,
      host: Figaro.env.subtext_ad_service_host
    }
  end

  def headers
    {
      'Content-Type': 'application/json',
      PUBLIC_KEY: config[:public_key],
      Authorization: "Bearer #{encoded_payload}"
    }
  end

  def payload
    {
      secretKey: config[:secret]
    }
  end

  def encoded_payload
    JWT.encode(payload, config[:secret], 'HS256')
  end

  def public_key
    unless config[:public_key].present?
      raise 'Subtext Ad Service public key not configured'
    end
    return config[:public_key]
  end

  def private_key
    unless config[:secret].present?
      raise 'Subtext Ad Service secret key not configured'
    end
    return config[:secret]
  end

end
