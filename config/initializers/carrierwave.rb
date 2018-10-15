CarrierWave.configure do |config|
  if Figaro.env.aws_access_key_id && Figaro.env.aws_secret_access_key
    # Beginning in Carrierwave v0.10.0, fog credentials get eager loaded.
    # This doesn't play well with some of the rake tasks, like +assets:precompile+ and +db:migrate+,
    # because the Figaro environment is not yet available.  So we skip setting the fog credentials
    # when they're unavailable.

    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => Figaro.env.aws_access_key_id,
      :aws_secret_access_key => Figaro.env.aws_secret_access_key
    }
  end

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
