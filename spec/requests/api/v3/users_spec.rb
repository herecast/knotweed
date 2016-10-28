require 'rails_helper'

RSpec.describe 'User API Endpoints', type: :request do
  describe 'GET /api/v3/user/:email'do
    let(:user) { FactoryGirl.create :user }

    context 'when email is attached to a user' do
      subject { get "/api/v3/user/?email=#{user.email}" }
      it 'returns 200' do
        subject
        expect(response.code).to eq '200'
      end

      it 'does not return any information in the response body' do
        subject
        expect(response.body).to eq '{}'
      end
    end

    context 'when the email is not found' do
      subject { get "/api/v3/user/?email=fake@email.com" }
      it 'returns 404' do
        subject
        expect(response.code).to eq '404'
      end

      it 'does not return any information in the response body' do
        subject
        expect(response.body).to eq '{}'
      end
    end
  end
end
