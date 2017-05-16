require 'spec_helper'

describe SessionsController, :type => :controller do
  describe 'Sign In' do
    before do
      @user = FactoryGirl.create :user, password: 'passw0rd', password_confirmation: 'passw0rd'
      @args = { email: @user.email,
                password: 'passw0rd'
      }
    end
    
    subject! do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      post :create, format: :json, user: @args 
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
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end
    it 'should respond with 201' do
      post :sign_in_with_token, format: :json, token: @sign_in_token.token
      expect(response.status).to eq 201
    end
    
    it 'should return expected fields' do
      post :sign_in_with_token, format: :json, token: @sign_in_token.token
      expect(JSON.parse(response.body)).to eq({ token: @user.authentication_token, email: @user.email }.stringify_keys)
    end
   
    context 'user is unconfirmed' do
      it 'comfirms the users account' do
        post :sign_in_with_token, format: :json, token: @sign_in_token.token
        @user.reload
        expect(@user.confirmed?).to eq true
      end
    end
  end
end
