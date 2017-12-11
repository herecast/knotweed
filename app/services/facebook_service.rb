module FacebookService
  include HTTParty
  extend self

  base_uri "https://graph.facebook.com"

  def get_user_info(access_token)
    options = { fields: "email, name, verified, age_range, timezone, gender",
                access_token: access_token
              }
    detect_error(get "#{base_uri}/v2.11/me", query: options)
  end

  def rescrape_url(content)
    query_line = "?scrape=true&access_token=#{ENV['FACEBOOK_APP_ID']}%7C#{ENV['FACEBOOK_APP_SECRET']}"
    if content.channel_type == 'Event'
      content.channel.event_instance_ids.each do |eiid|
        detect_error(post "#{base_uri}/#{query_line}&id=http://#{ENV['DEFAULT_CONSUMER_HOST']}/feed/#{content.id}/#{eiid}")
      end
    else
      detect_error(post "#{base_uri}/#{query_line}&id=http://#{ENV['DEFAULT_CONSUMER_HOST']}/feed/#{content.id}")
    end
  end

  private

  def detect_error(response)
    if response.code >= 400
      raise UnexpectedResponse.new(response)
    end
    response
  end
end

class FacebookService::UnexpectedResponse < ::StandardError
  attr_reader :response

  def initialize(response)
    @response = response
    super("An unexpected response was returned by the Facebook API: #{response.body}")
  end
end
