require "typhoeus/adapters/faraday"
require "faraday_middleware/aws_signers_v4"
Ethon.logger = Logger.new("/dev/null")
Searchkick.client = Elasticsearch::Client.new(
  url: ENV["ELASTICSEARCH_URL"],
  transport_options: {request: {timeout: 60}},
  retry_on_failure: true # https://github.com/ankane/searchkick/issues/351
) do |f|
  # we don't want to attempt to sign requests to our local elasticsearch instance on dev
  unless ENV["ELASTICSEARCH_URL"].present? and ENV["ELASTICSEARCH_URL"].include? 'localhost'
    if ENV["ELASTICSEARCH_URL"].include? 'es.amazonaws.com'
      f.request :aws_signers_v4, {
        credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"]),
        service_name: "es",
        region: "us-east-1"
      }
    end
  end
end
