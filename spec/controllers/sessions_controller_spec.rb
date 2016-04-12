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
end
