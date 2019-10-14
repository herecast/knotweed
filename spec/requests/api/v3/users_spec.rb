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
    subject { get '/api/v3/user', params: { email: email } }

    context 'with existing user email' do
      let(:user) { FactoryGirl.create :user }
      let(:email) { user.email }

      it 'responds with status OK' do
        subject
        expect(response.code).to eq '200'
      end
    end

    context 'with non-existent user email' do
      let(:email) { 'fakeemail@fake.com' }

      it 'responds with 404' do
        subject
        expect(response.code).to eq '404'
      end
    end
  end

  describe 'GET /api/v3/current_user' do
    context 'signed in ' do
      let(:user) { FactoryGirl.create :user }
      let(:headers) do
        json_headers['HTTP_AUTHORIZATION'] = \
          "Token token=#{user.authentication_token}, \
          email=#{user.email}"
        json_headers
      end

      it 'returns json representation of signed in user' do
        get '/api/v3/current_user', params: {}, headers: headers

        expect(response_json).to match(
          current_user: {
            id: user.id,
            name: user.name,
            email: user.email,
            created_at: user.created_at.iso8601,
            location: {
              id: user.location.id,
              city: user.location.city,
              state: user.location.state,
              latitude: an_instance_of(Float),
              longitude: an_instance_of(Float),
              image_url: user.location.image_url
            },
            location_confirmed: user.location_confirmed?,
            listserv_id: an_instance_of(String).or(be_nil),
            listserv_name: an_instance_of(String).or(be_nil),
            test_group: an_instance_of(String).or(be_nil),
            user_image_url: an_instance_of(String).or(be_nil),
            skip_analytics: user.skip_analytics,
            managed_organization_ids: an_instance_of(Array),
            can_publish_news: user.can_publish_news?,
            has_had_bookmarks: user.has_had_bookmarks,
            is_blogger: user.has_role?(:blogger),
            organization_subscriptions: user.organization_subscriptions.map do |os|
              {
                id: os.id,
                organization_name: os.organization.name
              }
            end,
            organization_hides: [],
            feed_card_size: user.feed_card_size,
            publisher_agreement_confirmed: user.publisher_agreement_confirmed
          }
        )
      end
    end
  end

  describe 'GET /api/v3/user/:email' do
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
      subject { get '/api/v3/user/?email=fake@email.com' }
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

  describe 'GET /api/v3/user' do
    let(:user_email) { 'chewbacca@canteen.org' }

    subject { get "/api/v3/user?email=#{user_email}" }

    it "returns not_found when no user present" do
      subject
      expect(response).to have_http_status :not_found
    end

    context "when user exists" do
      before do
        FactoryGirl.create :user, email: user_email
      end

      it "returns ok status" do
        subject
        expect(response).to have_http_status :ok
      end

      context "when case-insensitive email matches" do
        subject { get "/api/v3/user?email=#{user_email.upcase}" }

        it "returns ok status" do
          subject
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
