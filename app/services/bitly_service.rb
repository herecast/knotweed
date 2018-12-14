module BitlyService
  include HTTParty
  extend self

  base_uri "https://api-ssl.bitly.com/v3/shorten"

  def create_short_link(link)
    options = { query: { access_token: Figaro.env.bitly_oauth_key,
                         longUrl: link } }
    response = detect_error(get base_uri, options)
    response["data"]["url"]
  end

  protected

  def detect_error(response)
    if response.code >= 400
      raise BitlyExceptions::UnexpectedResponse.new(response)
    end

    response
  end
end
