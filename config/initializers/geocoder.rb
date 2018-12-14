# frozen_string_literal: true

require 'geocoder/lookups/freegeoip'

# Patch because freegeoip no longer supports http protocol
Geocoder::Lookup::Freegeoip.class_eval do
  def supported_protocols
    [:https]
  end
end

Geocoder.configure(
  # Geocoding options
  # timeout: 3,                 # geocoding service timeout (secs)
  lookup: :google, # name of geocoding service (symbol)
  ip_lookup: :freegeoip,
  freegeoip: {
    host: 'freegeoip.io',
    use_ssl: true
  },
  # language: :en,              # ISO-639 language code
  # use_https: false,           # use HTTPS for lookup requests? (if supported)
  # http_proxy: nil,            # HTTP proxy server (user:pass@host:port)
  # https_proxy: nil,           # HTTPS proxy server (user:pass@host:port)
  api_key: Figaro.env.gmaps_api_key, # API key for geocoding service
  cache: Redis.new # cache object (must respond to #[], #[]=, and #keys)
  # cache_prefix: 'geocoder:',  # prefix (string) to use for all cache keys

  # Exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and Timeout::Error
  # always_raise: [],

  # Calculation options
  # units: :mi,                 # :km for kilometers or :mi for miles
  # distances: :linear          # :spherical or :linear
)
