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

  describe '::rescrape_url' do
    before do
      @content = FactoryGirl.create(:content, :news)
    end

    let(:url) { "https://dailyuv.com/#{@content.id}" }

    let!(:successful_facebook_rescrape_request) {
      stub_request(:post, "https://graph.facebook.com/?access_token=#{ENV['FACEBOOK_APP_ID']}%7C#{ENV['FACEBOOK_APP_SECRET']}&id=http://#{ENV['DEFAULT_CONSUMER_HOST']}/#{@content.id}&scrape=true").
        with(:body => "", :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})
    }

    let!(:successful_facebook_profile_rescrape_request) {
      stub_request(:post, "https://graph.facebook.com/?access_token=#{ENV['FACEBOOK_APP_ID']}%7C#{ENV['FACEBOOK_APP_SECRET']}&id=http://#{ENV['DEFAULT_CONSUMER_HOST']}/profile/#{@content.organization_id}/#{@content.id}&scrape=true").
        with(:body => "", :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})
    }

    subject { FacebookService.rescrape_url(@content) }

    it "makes call for Facebook to rescrape url" do
      subject
      expect(successful_facebook_rescrape_request).to have_been_requested
      expect(successful_facebook_profile_rescrape_request).to have_been_requested
    end

    context "when content_type=Event" do
      before do
        @event = FactoryGirl.create(:event)
      end

      let!(:successful_facebook_event_rescrape_request) {
        stub_request(:post, "https://graph.facebook.com/?access_token=#{ENV['FACEBOOK_APP_ID']}%7C#{ENV['FACEBOOK_APP_SECRET']}&id=http://#{ENV['DEFAULT_CONSUMER_HOST']}/#{@event.content.id}/#{@event.event_instances.first.id}&scrape=true").
          with(:body => "", :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})
      }

      let!(:successful_facebook_profile_event_rescrape_request) {
        stub_request(:post, "https://graph.facebook.com/?access_token=#{ENV['FACEBOOK_APP_ID']}%7C#{ENV['FACEBOOK_APP_SECRET']}&id=http://#{ENV['DEFAULT_CONSUMER_HOST']}/profile/#{@event.content.organization_id}/#{@event.content.id}/#{@event.event_instances.first.id}&scrape=true").
          with(:body => "", :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})
      }

      subject { FacebookService.rescrape_url(@event.content) }

      it "makes call to Facebook to scrape event instance URLs" do
        subject
        expect(successful_facebook_event_rescrape_request).to have_been_requested
        expect(successful_facebook_profile_event_rescrape_request).to have_been_requested
      end
    end
  end
end
