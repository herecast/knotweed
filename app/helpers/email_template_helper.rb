module EmailTemplateHelper
  def url_for_consumer_app(url)
    "http://#{consumer_host}#{url}"
  end

  def consumer_host
    ENV.fetch('DEFAULT_CONSUMER_HOST', "dailyuv.com")
  end
end
