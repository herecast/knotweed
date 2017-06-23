module FacebookService
  include HTTParty
  extend self

  base_uri "https://graph.facebook.com/v2.9/me"

  def get_user_info(access_token)
    options = { fields: "email, name, verified, age_range, timezone, gender",
                access_token: access_token
              }
    detect_error(get base_uri, query: options)
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
