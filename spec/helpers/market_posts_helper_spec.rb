require 'spec_helper'

include ContentsHelper

describe MarketPostsHelper, type: :helper do
  describe '#market_contact_display' do
    let(:market_post) {MarketPost.new}
    subject { helper.market_contact_display(market_post) }
    context 'Given a market_post with a phone' do
      before do
        market_post.contact_phone = '555-5555'
      end

      it 'includes the phone number' do
        expect(subject).to include('555-5555')
      end
    end

    context 'Given a market_post with an email' do
      before do
        market_post.contact_email = 'test@example.com'
      end

      it 'includes the email' do
        expect(subject).to include('test@example.com')
      end
    end

    context 'Given a market_post with an email and phone' do
      before do
        market_post.contact_email = 'test@example.com'
        market_post.contact_phone = '555-5555'
      end

      it 'includes the email' do
        expect(subject).to include('test@example.com')
      end

      it 'includes the phone number' do
        expect(subject).to include('555-5555')
      end
    end
  end

  describe '#market_post_url_for_email' do
    let(:market_post) { FactoryGirl.create :market_post }
    subject { helper.market_post_url_for_email(market_post) }

    let(:content_path) { ux2_content_path(market_post.content) }
    let(:utm_string) { "?utm_medium=email&utm_source=rev-pub&utm_campaign=20151201&utm_content=#{content_path}" }

    context 'consumer_app set from request' do
      let(:consumer_app) { double(uri: 'http://my-uri.example') }
      before { allow(ConsumerApp).to receive(:current).and_return(consumer_app) }

      it 'uses consumer app uri' do
        expect(subject).to eql "#{consumer_app.uri}/market/#{market_post.content.id}"
      end
    end

    context 'consumer_app not set; @base_uri set from controller' do
      before do
        @base_uri = 'http://event.foo'
        allow(ConsumerApp).to receive(:current).and_return(nil)
      end

      it 'uses @base_uri, and market_post.content.id' do
        expect(subject).to eql "#{@base_uri}/market/#{market_post.content.id}"
      end
    end

    context 'if not consumer_app, or @base_uri;' do
      before do 
        @base_uri = nil
        allow(ConsumerApp).to receive(:current).and_return(nil)
      end

      it 'uses a default url' do
        expect(subject).to eql "http://www.dailyuv.com/market"
      end
    end
  end
end
