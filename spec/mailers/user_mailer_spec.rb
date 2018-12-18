# frozen_string_literal: true

require 'spec_helper'

describe UserMailer, type: :mailer do
  let(:body_html) { subject.body.parts.find { |p| p.content_type.match /html/ }.body.raw_source }
  let(:body_text) { subject.body.parts.find { |p| p.content_type.match /plain/ }.body.raw_source }

  before(:each) do
    allow(Figaro.env).to receive(:default_consumer_host)\
      .and_return('test.localhost')
  end

  describe 'sign_in_link' do
    context 'given a sign_in_token' do
      let(:user) { FactoryGirl.build :user }
      let(:sign_in_token) { FactoryGirl.build :sign_in_token, user: user }

      subject { described_class.sign_in_link(sign_in_token) }

      it 'includes a link to the consumer app to sign in with the auth_token' do
        expected_url = "http://#{Figaro.env.default_consumer_host}/sign_in?auth_token=#{sign_in_token.token}"
        expect(body_html).to include(expected_url)
        expect(body_text).to include(expected_url)
      end

      it 'is sent to the correct user email' do
        expect(subject.to).to include user.email
      end
    end
  end
end
