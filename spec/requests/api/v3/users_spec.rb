require 'rails_helper'

RSpec.describe 'User API Endpoints', type: :request do
  let(:json_headers) {
    {
      'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json'
    }
  }

  describe 'GET /api/v3/current_user' do
    context 'signed in ' do
      let(:user) { FactoryGirl.create :user }
      let(:headers) {
        json_headers['HTTP_AUTHORIZATION'] = \
          "Token token=#{user.authentication_token}, \
          email=#{user.email}"
        json_headers
      }

      it 'returns json representation of signed in user' do
        get '/api/v3/current_user', params: {}, headers: headers

        expect(response_json).to match({
          current_user: {
            id: user.id,
            name: user.name,
            email: user.email,
            created_at: user.created_at.iso8601,
            location: {
              id: user.location.id,
              city: user.location.city,
              state: user.location.state
            },
            location_confirmed: user.location_confirmed?,
            listserv_id: an_instance_of(String).or(be_nil),
            listserv_name: an_instance_of(String).or(be_nil),
            test_group: an_instance_of(String).or(be_nil),
            user_image_url: an_instance_of(String).or(be_nil),
            events_ical_url: an_instance_of(String).or(be_nil),
            skip_analytics: user.skip_analytics,
            managed_organization_ids: an_instance_of(Array),
            can_publish_news: user.can_publish_news?,
            has_had_bookmarks: user.has_had_bookmarks,
            is_blogger: user.has_role?(:blogger)
          }
        })
      end
    end
  end

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

  describe 'POST /api/v3/users/sign_in_with_token' do
    context 'with token in json payload' do
      let(:token) { SecureRandom.hex(10) }

      subject {
        post "/api/v3/users/sign_in_with_token",
          params: {token: token}.to_json,
          headers: json_headers
      }

      context 'When SignInToken.authenticate returns a user' do
        let(:user) {
          FactoryGirl.create :user
        }

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

  describe 'POST /api/v3/users/email_signin_link' do
    context 'Given an email from an existing user' do
      let(:user) {
        FactoryGirl.create :user
      }

      subject {
        post "/api/v3/users/email_signin_link",
          params: {email: user.email}.to_json,
          headers: json_headers
      }

      it 'returns 201 status code' do
        subject

        expect(response.code).to eq '201'
      end

      it 'generates a sign in token, and sends the email' do
        sign_in_token = FactoryGirl.create(:sign_in_token, user: user)
        allow(SignInToken).to receive(:create).with(user: user).and_return(sign_in_token)

        expect(NotificationService).to receive(:sign_in_link).with(
          sign_in_token
        )

        subject
      end
    end

    context 'Given an email which does not match a user account' do
      subject {
        post "/api/v3/users/email_signin_link",
          params: {email: "notauser@somewhere.com"}.to_json,
          headers: json_headers
      }

      it 'responds with 422 status code' do
        subject
        expect(response.code).to eq '422'
      end
    end
  end
end
