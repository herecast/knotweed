module MailchimpService
  include HTTParty
  extend self

  format :json
  base_uri "https://" + Figaro.env.mailchimp_api_host.to_s + '/3.0'
  basic_auth 'user', Figaro.env.mailchimp_api_key.to_s
  headers 'Content-Type' => 'application/json',
          'Accept' => 'application/json'

  # Does upsert to create/update member to list
  #
  # @param [Subscription]
  def subscribe(subscription)
    if subscription.listserv.mc_list_id?
      if subscription.confirmed?
        unless subscription.unsubscribed?
          subscriber_hash = Digest::MD5.hexdigest(subscription.email)

          detect_error(
            put("/lists/#{subscription.listserv.mc_list_id}/members/#{subscriber_hash}",
              body: SubscriptionSerializer.new(subscription).to_json
            )
          )
        else
          raise "Subscription #{subscription.id} is unsubscribed."
        end
      else
        raise "Subscription #{subscription.id} is not confirmed."
      end
    else
      raise MissingListId.new(subscription.listserv)
    end
  end

  # Does delete to remove member from list
  #
  # @param [Subscription]
  def unsubscribe(subscription)
    if subscription.listserv.mc_list_id?
      if subscription.unsubscribed?
        subscriber_hash = Digest::MD5.hexdigest(subscription.email)
        detect_error delete("/lists/#{subscription.listserv.mc_list_id}/members/#{subscriber_hash}")
      else
        raise "Subscription #{subscription.id} is not unsubscribed."
      end
    else
      raise MissingListId.new(subscription.listserv)
    end
  end

  # Creates a campaign in mailchimp with the listserv mc_list_id
  #
  # @param [ListservDigest]
  # @param [String] - A string representing the body of the email
  # @return [Hash] - The response json parsed into hash from Mailchimp api
  def create_campaign(digest, content = nil)
    resp = detect_error post('/campaigns', {
      body: CampaignSerializer.new(digest).to_json
    })
    if content.present?
      put_campaign_content(resp.parsed_response['id'], content)
    end
    resp.parsed_response.deep_symbolize_keys
  end

  # Updates a campaign in mailchimp with the digest.campaign_id
  #
  # @param [ListservDigest]
  # @param [String] - A string representing the body of the email
  # @return [Hash] - The response json parsed into hash from Mailchimp api
  def update_campaign(digest, content = nil)
    resp = detect_error patch("/campaigns/#{digest.campaign_id}", {
      body: CampaignSerializer.new(digest).to_json
    })
    if content.present?
      put_campaign_content(digest.campaign_id, content)
    end
    resp.parsed_response.deep_symbolize_keys
  end

  # Sets campaign content/body
  #
  # @param [string] - Campaign id
  # @param [string] - content
  def put_campaign_content(campaign_id, content)
    detect_error put("/campaigns/#{campaign_id}/content", {
      body: {
        html: content
      }.to_json
    })
  end

  # Sends campaign now on mailchimp api
  #
  # @param [String] - campaign id
  def send_campaign(campaign_id)
    detect_error post("/campaigns/#{campaign_id}/actions/send")
  end

  protected
  def detect_error(response)
    if response.code >= 400
      raise UnexpectedResponse.new(response)
    end
    response
  end

  # set debug_output based on environment
  def set_debug_output
    unless Rails.env.production?
      debug_output
    end
  end
  set_debug_output

end
