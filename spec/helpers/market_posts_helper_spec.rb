require 'spec_helper'

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
    let(:content_path) { ux2_content_path(market_post.content) }
    let(:utm_string) { "?utm_medium=email&utm_source=rev-pub&utm_content=#{ux2_content_path(market_post.content)}" }
    before { allow(Figaro.env).to receive(:default_consumer_host).and_return("test.com") }

    subject { helper.market_post_url_for_email(market_post) }

    it 'uses default_consumer_host' do
      expect(subject).to eql "http://#{Figaro.env.default_consumer_host}/feed/#{market_post.content.id}#{utm_string}"
    end

  end
end
