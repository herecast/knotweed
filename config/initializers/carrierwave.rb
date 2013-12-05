CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => Figaro.env.aws_access_key_id,
    :aws_secret_access_key => Figaro.env.aws_secret_access_key
  }
  config.fog_directory = Figaro.env.aws_bucket_name
  config.ignore_download_errors = false

  if Rails.env.test? 
    config.storage = :file
  else
    config.storage = :fog
  end

end

