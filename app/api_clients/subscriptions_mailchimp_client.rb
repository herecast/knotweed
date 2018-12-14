# Subtext has a special MailChimp account for managing organization subscriber lists.
# This module is a wrapper for that account.

require 'httparty'

module SubscriptionsMailchimpClient
  include HTTParty
  extend self

  format     :json
  base_uri   "https://#{Figaro.env.subscriptions_mailchimp_api_host}/3.0"
  basic_auth 'user', Figaro.env.subscriptions_mailchimp_api_key.to_s
  headers    'Content-Type' => 'application/json',
             'Accept' => 'application/json'

  # Returns the entire collection of subscriber lists, even though the MailChimp API does pagination.
  def lists
    Enumerator.new do |y|
      page_size = 100
      page_num = 0
      begin
        pagination_params = { offset: page_num * page_size, count: page_size }.to_param
        lists = get("/lists?#{pagination_params}")['lists']
        lists.each { |list| y << list }
        page_num += 1
      end while lists.any?
    end
  end

  def create_campaign(list_identifier:, subject:, title:, from_name:, reply_to:)
    payload = { body: {
      type: 'regular',
      recipients: { list_id: list_identifier },
      settings: campaign_settings(subject, title, from_name, reply_to),
    }.to_json }
    resp = detect_error post("/campaigns", payload)
    resp['id']
  end

  def update_campaign(campaign_identifier:, subject:, title:, from_name:, reply_to:)
    payload = { body: {
      settings: campaign_settings(subject, title, from_name, reply_to),
    }.to_json }
    detect_error patch("/campaigns/#{campaign_identifier}", payload)
  end

  def set_content(campaign_identifier:, html:)
    payload = { body: { html: html }.to_json }
    detect_error put("/campaigns/#{campaign_identifier}/content", payload)
  end

  def get_status(campaign_identifier:)
    resp = detect_error get("/campaigns/#{campaign_identifier}")
    resp['status']
  end

  protected

  def campaign_settings(subject, title, from_name, reply_to)
    campaign_settings = {
      subject_line: subject,
      title: title,
      from_name: from_name,
      reply_to: reply_to,
    }
  end

  def detect_error(response)
    unless response.success?
      raise UnexpectedResponse.new(response)
    end

    response
  end
end

class SubscriptionsMailchimpClient::UnexpectedResponse < ::StandardError
  attr_reader :response

  def initialize(response)
    super("An unexpected response was returned by the Mailchimp API:  #{response.body}")
  end
end
