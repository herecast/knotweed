require 'spec_helper'

describe SessionsController do
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
      response.status.should eq 201
    end

    it 'should return expected fields' do
      JSON.parse(response.body).should eq({ token: @user.authentication_token, email: @user.email }.stringify_keys)
    end
  end
end
