require 'rails_helper'

RSpec.describe FacebookService do
  subject { FacebookService }

  let!(:successful_facebook_request) {
    stub_request(:get, "https://graph.facebook.com/v2.11/me?access_token=123123123123123&fields=email,%20name,%20verified,%20age_range,%20timezone,%20gender").
             with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
                      to_return(:status => 200, :body => "", :headers => {})
  }
  
  let!(:failed_facebook_request) {
    stub_request(:get, "https://graph.facebook.com/v2.11/me?access_token=BadToken&fields=email,%20name,%20verified,%20age_range,%20timezone,%20gender").
             with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
                      to_return(:status => 400, :body => "", :headers => {})
  }
  
  it { is_expected.to respond_to(:get_user_info) }

  describe 'get_user_info' do
    it 'requests the users info' do
      FacebookService.get_user_info("123123123123123")
      expect(successful_facebook_request).to have_been_requested
    end

    it 'catches errors in the API response' do
      expect{ FacebookService.get_user_info("BadToken") }.to raise_error(FacebookService::UnexpectedResponse)
    end
  end
end
