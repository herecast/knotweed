CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => Figaro.env.aws_access_key_id,
    :aws_secret_access_key => Figaro.env.aws_secret_access_key
  }
  config.fog_directory = Figaro.env.aws_bucket_name
  config.ignore_download_errors = false
  config.asset_host = ENV['CLOUDFRONT_BUCKET_ENDPOINT'] || 'https://d3ctw1a5413a3o.cloudfront.net'
  config.fog_attributes = { :cache_control => 'max-age=' + 1.month.to_s }

  if Rails.env.test?
    config.storage = :file
  else
    config.storage = :fog
  end

end
