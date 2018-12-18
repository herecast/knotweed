# frozen_string_literal: true

require 'spec_helper'

describe SessionsController, type: :controller do
  describe 'Sign In' do
    before do
      @user = FactoryGirl.create :user, password: 'passw0rd', password_confirmation: 'passw0rd'
      @args = { email: @user.email,
                password: 'passw0rd' }
    end

    subject! do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      post :create, format: :json, params: { user: @args }
    end

    it 'should respond with 201' do
      expect(response.status).to eq 201
    end

    it 'should return expected fields' do
      expect(JSON.parse(response.body)).to eq({ token: @user.authentication_token, email: @user.email }.stringify_keys)
    end
  end

  describe 'Sign in with token' do
    before do
      @user = FactoryGirl.create :user, password: 'passw0rd',
                                        password_confirmation: 'passw0rd',
                                        confirmed_at: nil
      @sign_in_token = FactoryGirl.create :sign_in_token, user: @user
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end
    it 'should respond with 201' do
      post :sign_in_with_token, format: :json, params: { token: @sign_in_token.token }
      expect(response.status).to eq 201
    end

    it 'should return expected fields' do
      post :sign_in_with_token, format: :json, params: { token: @sign_in_token.token }
      expect(JSON.parse(response.body)).to eq({ token: @user.authentication_token, email: @user.email }.stringify_keys)
    end

    context 'user is unconfirmed' do
      it 'comfirms the users account' do
        post :sign_in_with_token, format: :json, params: { token: @sign_in_token.token }
        @user.reload
        expect(@user.confirmed?).to eq true
      end
    end
  end

  describe 'Sign in with facebook' do
    before do
      @existing_user = FactoryGirl.create :user
      @existing_social_login = FactoryGirl.create :social_login,
                                                  provider: 'facebook',
                                                  uid: '123456',
                                                  user: @existing_user
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    let(:existing_user_fb_response) do
      { email: @existing_user.email,
        name: @existing_user.name,
        id: '123456',
        verified: true,
        age_range: { min: 21 },
        timezone: -6,
        gender: 'male' }
    end

    let!(:new_facebook_user_response) do
      { email: Faker::Internet.email,
        name: Faker::Name.name,
        id: '7891011',
        verified: true,
        age_range: { min: 21 },
        timezone: -6,
        gender: 'male' }
    end

    let!(:no_email_facebook_response) do
      { name: Faker::Name.name,
        id: '7891011',
        verified: true,
        age_range: { min: 21 },
        timezone: -6,
        gender: 'male' }
    end

    context 'when a user has an existing account' do
      it 'returns the correct user and signs them in' do
        allow(FacebookService).to receive(:get_user_info).and_return(existing_user_fb_response)
        post :oauth, params: { accessToken: 'myFak3t0k3n' }
        @existing_user.reload
        expect(JSON.parse(response.body)).to eq({ email: @existing_user.email, token: @existing_user.authentication_token }.stringify_keys)
      end
    end

    context 'when the user is creating a new account' do
      let(:location) do
        FactoryGirl.create :location
      end

      before do
        allow(FacebookService).to receive(:get_user_info).and_return(new_facebook_user_response)
      end

      subject do
        post :oauth, params: { accessToken: 'myFak3t0k3n', location_id: location.slug }
      end

      it 'creates a new user ' do
        expect { subject }.to change { User.count }.by(1)
      end

      it 'creates a new social login record for the user' do
        expect { subject }.to change { SocialLogin.count }.by(1)
      end

      it 'signs in the created user' do
        subject
        user = User.find_by_email(new_facebook_user_response[:email])
        expect(JSON.parse(response.body)).to eq({ email: user.email, token: user.authentication_token }.stringify_keys)
      end

      context 'when the user does not allow permission for email' do
        before do
          allow(FacebookService).to receive(:get_user_info).and_return(no_email_facebook_response)
        end

        it 'does not create a new user' do
          expect { subject }.to_not change { User.count }
        end

        it 'returns the an error with the missing fields' do
          subject
          expect(JSON.parse(response.body)).to eq({ error: 'There was a problem signing in', missing_fields: 'email' }.stringify_keys)
        end
      end
    end
  end
end
