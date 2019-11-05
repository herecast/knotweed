# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User API Endpoints', type: :request do
  let(:json_headers) do
    {
      'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json'
    }
  end

  describe 'GET /api/v3/user' do
    before do
      @email = 'fake@email.com'
      FactoryGirl.create :user, email: @email
    end

    context "when no user attached to email" do
      subject { get "/api/v3/user?email=weird@email.com" }

      it "has not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when email is attached to user" do
      subject { get "/api/v3/user?email=#{@email}" }

      it "has ok status" do
        subject
        expect(response).to have_http_status :ok
      end

      context "when odd capialization" do
        before do
          @email = 'FaKe@eMail.cOm'
        end

        it "has ok status" do
          subject
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe 'POST /api/v3/users/sign_in_with_token' do
    context 'with token in json payload' do
      let(:token) { SecureRandom.hex(10) }

      subject do
        post '/api/v3/users/sign_in_with_token',
             params: { token: token }.to_json,
             headers: json_headers
      end

      context 'When SignInToken.authenticate returns a user' do
        let(:user) do
          FactoryGirl.create :user
        end

        before do
          allow(SignInToken).to receive(:authenticate).with(token).and_return(user)
        end

        it 'responds with status code 201' do
          subject
          expect(response.code).to eq '201'
        end

        it 'returns an authentication object' do
          subject

          expect(response_json).to match(
            email: user.email,
            token: user.authentication_token
          )
        end
      end

      context 'When SignInToken.authenticate returns nil' do
        before do
          allow(SignInToken).to receive(:authenticate).with(token).and_return(nil)
        end

        it 'responds with 422 status code' do
          subject
          expect(response.code).to eq '422'
        end
      end
    end
  end
end
