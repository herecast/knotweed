# frozen_string_literal: true

require 'spec_helper'

describe 'CurrentUser Passwords endpoints', type: :request do
  before do
    @password = 'password'
    @user = FactoryGirl.create :user,
      password: @password,
      password_confirmation: @password
  end

  let(:headers) { auth_headers_for(@user) }

  describe "POST /api/v3/current_users/password_validation" do
    context "when no user logged in" do
      subject do
        post '/api/v3/current_users/password_validation',
          params: { password: @password }
      end

      it "returns unauthorized status" do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context "when user logged in and send wrong password" do
      subject do
        post '/api/v3/current_users/password_validation',
          params: { password: 'wrong-password' },
          headers: headers
      end

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when user logged in and sends correct password" do
      subject do
        post '/api/v3/current_users/password_validation',
          params: { password: @password },
          headers: headers
      end

      it "returns ok status" do
        subject
        expect(response).to have_http_status :ok
      end
    end
  end
end