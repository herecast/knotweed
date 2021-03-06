# frozen_string_literal: true

module EmailTemplateHelper
  def url_for_consumer_app(url = '/')
    "http://#{consumer_host}#{url}"
  end

  def consumer_host
    Figaro.env.default_consumer_host || 'herecast.us'
  end
end
