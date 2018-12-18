# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BitlyService do
  subject { BitlyService }

  let!(:valid_bitly_request) do
    stub_request(:get, "https://api-ssl.bitly.com/v3/shorten?access_token=#{Figaro.env.bitly_oauth_key}&longUrl=http://example.com")
      .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: { data: { url: 'http://bit.ly/12345' } }.to_json, headers: {})
  end

  let!(:invlaid_bitly_request) do
    stub_request(:get, "https://api-ssl.bitly.com/v3/shorten?access_token=#{Figaro.env.bitly_oauth_key}&longUrl=BadLink")
      .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Ruby' })
      .to_return(status: 400, body: '', headers: {})
  end

  it { is_expected.to respond_to(:create_short_link) }

  describe 'create_short_link' do
    it 'returns a bitly link for the content link' do
      BitlyService.create_short_link('http://example.com')
      expect(valid_bitly_request).to have_been_requested
    end

    it 'catches errors in the API response' do
      expect { BitlyService.create_short_link('BadLink') }.to raise_error(BitlyExceptions::UnexpectedResponse)
    end
  end
end
