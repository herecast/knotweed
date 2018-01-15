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
  def update_subscription(subscription)
    if subscription.listserv.mc_sync?
      unless subscription.mc_unsubscribed_at?
        subscriber_hash = Digest::MD5.hexdigest(subscription.email)

        if subscription.user
          find_or_create_merge_field(subscription.listserv.mc_list_id, 'ZIP',
                                     name: 'Zip', type: 'zip')
          find_or_create_merge_field(subscription.listserv.mc_list_id, 'CITY',
                                     name: 'City', type: 'text')
          find_or_create_merge_field(subscription.listserv.mc_list_id, 'STATE',
                                     name: 'State', type: 'text')
        end

        detect_error(
          put("/lists/#{subscription.listserv.mc_list_id}/members/#{subscriber_hash}",
            body: SubscriptionSerializer.new(subscription).to_json
          )
        )
      end
    else
      raise MissingListId.new(subscription.listserv)
    end
  end

  # Does upsert to create/update member to list
  #
  # @TODO: deprecate this method
  #
  # @param [Subscription]
  def subscribe(subscription)
    if subscription.confirmed?
      unless subscription.unsubscribed?
        update_subscription(subscription)
      else
        raise "Subscription #{subscription.id} is unsubscribed."
      end
    else
      raise "Subscription #{subscription.id} is not confirmed."
    end
  end

  # Does delete to remove member from list
  #
  # @TODO: deprecate this method
  #
  # @param [Subscription]
  def unsubscribe(subscription)
    if subscription.unsubscribed?
      update_subscription(subscription)
    else
      raise "Subscription #{subscription.id} is not unsubscribed."
    end
  end

  # Creates a campaign in mailchimp with the listserv mc_list_id
  #
  # @param [ListservDigest]
  # @param [String] - A string representing the body of the email
  # @return [Hash] - The response json parsed into hash from Mailchimp api
  def create_campaign(digest, content = nil)
    digest.update mc_segment_id: create_segment(digest)[:id]

    resp = detect_error post('/campaigns', {
      body: CampaignSerializer.new(digest).to_json
    })
    if content.present?
      put_campaign_content(resp.parsed_response['id'], content)
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

  # Get interest categories for list
  #
  # @param [string] - list_id
  # @return [Array<Hash>]
  def interest_categories(list_id)
    data = detect_error get("/lists/#{list_id}/interest-categories")
    data['categories'].collect{|c| c.slice('id','title','type','list_id', 'display_order').symbolize_keys}
  end

  # Get interests for list and category
  #
  # @param [string] - list_id
  # @param [string] - category_id
  # @return [Array<Hash>]
  def interests(list_id, category_id)
    data = detect_error get("/lists/#{list_id}/interest-categories/#{category_id}/interests")
    data['interests'].collect{|c| c.slice('id','category_id','list_id','name', 'display_order').symbolize_keys}
  end

  # Find/create interest-category by name
  #
  # @param [String] - list_id
  # @param [String] - digest name
  # @return [Hash]
  def find_or_create_category(list_id, name, options={})
    group = interest_categories(list_id).find do |category|
      category[:title] == name
    end

    return group if group

    data = detect_error(post("/lists/#{list_id}/interest-categories", body: {
      type: options[:type] || 'checkboxes',
      display_order: options[:display_order] || 0,
      title: name
    }.to_json))

    group = data.slice('id','title','type','list_id','display_order').symbolize_keys

    return group
  end

  # Find/create digest by name
  #
  # @param [String] - list_id
  # @param [String] - digest name
  # @return [Hash]
  def find_or_create_digest(list_id, name)
    category = find_or_create_category(list_id, 'digests', {type: 'checkboxes'})

    interest = interests(list_id, category[:id]).find do |interest|
      interest[:name] == name
    end

    return interest if interest

    data = detect_error(post("/lists/#{list_id}/interest-categories/#{category[:id]}/interests", body: {
      name: name
    }.to_json))

    interest = data.slice('id','name','type','category_id','list_id','display_order').symbolize_keys

    return interest
  end

  def add_unsubscribe_hook(list_id)
    data = detect_error(get("/lists/#{list_id}/webhooks"))
    if data['webhooks'].empty?
      detect_error(post("/lists/#{list_id}/webhooks", body: {
        url: "#{Figaro.env.default_host}/api/v3/subscriptions/unsubscribe_from_mailchimp",
        events: { subscribe: false, unsubscribe: true, profile: false, cleaned: false, upemail: false, campaign: false },
        sources: { user: true, admin: true, api: true }
      }.to_json))
    end

  end

  def rename_digest(list_id, old_name, new_name)
    if new_name.present?
      if old_name.present?
        category_id = find_or_create_category(list_id, 'digests')[:id]
        interest_id = find_or_create_digest(list_id, old_name)[:id]

        detect_error patch("/lists/#{list_id}/interest-categories/#{category_id}/interests/#{interest_id}",
                            body: {
                              name: new_name
                            }.to_json
                          )
      else
        find_or_create_digest(list_id, new_name)
      end
    end
  end

  # Get merge-fields for list
  #
  # @param [string] - list_id
  # @return [Array<Hash>]
  def merge_fields(list_id)
    data = detect_error get("/lists/#{list_id}/merge-fields")
    data['merge_fields'].collect{|c| c.slice('tag', 'merge_id', 'name', 'type',
                                      'required', 'default_value','display_order',
                                      'public').symbolize_keys}
  end

  # Find/create merge field
  #
  # @param [String] - list_id
  # @param [String] - name/title
  # @param [Hash] - options
  # @return [Hash]
  def find_or_create_merge_field(list_id, tag, options = {})
    field = merge_fields(list_id).find do |mf|
      mf[:tag] == tag
    end

    return field if field

    data = detect_error(post("/lists/#{list_id}/merge-fields", body: {
      tag: tag,
      name: options[:name] || tag.titleize,
      type: options[:type] || "text",
      required: options[:required] || false,
      public: options[:public] || true
    }.to_json))

    field = data.slice('tag', 'merge_id', 'name', 'type', 'required', 'default_value',
                       'display_order', 'public').symbolize_keys
    return field
  end

  # create and return a segment for the digest subscribers
  #
  # @param [ListservDigest]
  # @return [Hash] - Mailchimp api's segment (symbolized)
  def create_segment(digest)
    if digest.subscriber_emails.any?
      if digest.listserv.mc_list_id.present?
        detect_error(post("/lists/#{digest.listserv.mc_list_id}/segments", body: {
          name: "#{digest.listserv.name}-#{digest.id}",
          static_segment: digest.subscriber_emails
        }.to_json)).deep_symbolize_keys
      else
        raise MailchimpService::MissingListId.new(digest.listserv)
      end
    else
      raise MailchimpService::NoSubscribersPresent.new(digest)
    end
  end

  def get_campaign_report campaign_id
    detect_error(get("/reports/#{campaign_id}")).deep_symbolize_keys
  end

  def get_campaign_clicks_report campaign_id
    detect_error(get("/reports/#{campaign_id}/click-details")).deep_symbolize_keys
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
