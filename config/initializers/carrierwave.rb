CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => Figaro.env.aws_access_key_id || 'dummy',
    :aws_secret_access_key  => Figaro.env.aws_secret_access_key || 'dummy'
  }

  config.fog_directory = Figaro.env.aws_bucket_name
  config.ignore_download_errors = false
  config.asset_host = ENV['CLOUDFRONT_BUCKET_ENDPOINT'] || 'https://d3ctw1a5413a3o.cloudfront.net'

  # this is a location for CDN switch in future
  # config.asset_host = 'http://stage-cdn.subtext.org'

  config.fog_attributes = { :cache_control => 'max-age=' + 1.month.to_s }

  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  else
    config.storage = :fog
  end

end
