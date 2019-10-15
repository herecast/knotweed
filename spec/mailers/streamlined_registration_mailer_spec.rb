# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamlinedRegistrationMailer do
  describe 'confirmation_instructions' do
    before do
      allow(Figaro.env).to receive('default_consumer_host').and_return('test.localhost')
      @password = Devise.friendly_token(8)
      location = FactoryGirl.create :location, city: 'Hartford'
      @user = User.new(name: Faker::Name.name,
                       email: Faker::Internet.email,
                       location: location,
                       password: @password,
                       source: 'market_message',
                       handle: 'handle')
      @user.skip_confirmation!
      @user.save!
      @user.send(:generate_confirmation_token)
      @user.confirmed_at = nil
      @token = @user.instance_variable_get(:@raw_confirmation_token)
      @user.save!
      @mail = StreamlinedRegistrationMailer.confirmation_instructions(@user,
                                                                      @token,
                                                                      password: @password).deliver_now
    end

    it 'sends an email with the users passowrd and confirmation link' do
      expect(StreamlinedRegistrationMailer.deliveries.present?).to eq(true)
      expect(@mail.body.include?(@password)).to eq(true)
      expect(@mail.body.include?(@user.instance_variable_get(:@raw_confirmation_token))).to eq(true)
      expect(@mail.to.first).to eq @user.email
      expect(@mail.body.include?("http://#{Figaro.env.default_consumer_host}/sign_up/confirm/#{@token}"))
    end
  end
end
