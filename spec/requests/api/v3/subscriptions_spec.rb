# frozen_string_literal: true

require 'rails_helper'

def json_datetime(dt)
  dt.try(:to_formatted_s, :iso8601)
end

RSpec.describe 'Subscriptions Endpoints', type: :request do
  describe 'GET /api/v3/subscriptions' do
    let(:user) { FactoryGirl.create :user }
    let(:auth_headers) { auth_headers_for(user) }

    context 'when not signed in;' do
      it 'responds with 401 (UnAuthorized)' do
        get '/api/v3/subscriptions'
        expect(response.status).to eql 401
      end
    end

    context 'when signed in;' do
      let(:url_params) { {} }

      subject { get '/api/v3/subscriptions', params: url_params, headers: auth_headers }

      context 'given some subscriptions exist;' do
        let!(:user_subscriptions) { FactoryGirl.create_list :subscription, 3, user: user }
        let!(:other_subscriptions) { FactoryGirl.create_list :subscription, 3 }

        it 'returns subscriptions owned by user only' do
          subject
          returned = response_json[:subscriptions]

          expect(returned.count).to be user_subscriptions.count

          returned.each do |sub|
            expect(sub).to match(a_hash_including(
                                   user_id: user.id,
                                   id: a_kind_of(String),
                                   listserv_id: a_kind_of(Integer),
                                   email: a_kind_of(String),
                                   name: a_kind_of(String),
                                   email_type: a_kind_of(String),
                                   created_at: a_kind_of(String),
                                   confirmed_at: a_kind_of(String).or(be_nil),
                                   unsubscribed_at: a_kind_of(String).or(be_nil)
                                 ))
          end
        end

        it 'paginates' do
          url_params[:page] = 1
          url_params[:per_page] = 1

          subject

          expect(response_json[:subscriptions].count).to eql 1

          expect(response_json[:meta]).to match(
            total_count: user_subscriptions.count,
            page: 1,
            per_page: 1,
            page_count: 3
          )
        end
      end
    end
  end

  describe 'PATCH /api/v3/subscriptions/:key' do
    let(:subscription) { FactoryGirl.create :subscription, email_type: 'html' }
    let(:attrs) do
      {
        email_type: 'text',
        name: 'John Doe'
      }
    end

    subject { patch "/api/v3/subscriptions/#{subscription.key}", params: { subscription: attrs } }

    it 'will update email_type' do
      expect { subject }.to change {
        subscription.reload.email_type
      }.to 'text'
    end

    it 'will update name' do
      expect { subject }.to change {
        subscription.reload.name
      }.to 'John Doe'
    end
  end

  describe 'GET /api/v3/subscriptions/:key' do
    let(:subscription) { FactoryGirl.create :subscription }
    subject { get "/api/v3/subscriptions/#{subscription.key}" }

    it 'returns subscription' do
      subject

      expect(response_json[:subscription]).to match(
        id: subscription.key,
        email: subscription.email,
        name: subscription.name,
        listserv_id: subscription.listserv_id,
        user_id: subscription.user_id,
        created_at: json_datetime(subscription.created_at),
        confirmed_at: json_datetime(subscription.confirmed_at),
        email_type: subscription.email_type,
        unsubscribed_at: json_datetime(subscription.unsubscribed_at)
      )
    end

    context 'subscription does not exist' do
      subject { get "/api/v3/subscriptions/#{SecureRandom.uuid}" }

      it 'returns 404 (not found)' do
        subject
        expect(response.status).to eql 404
      end
    end
  end

  describe 'DELETE /api/v3/subscriptions/{listserv_id}/{base64_email}' do
    let(:listserv) { FactoryGirl.create :listserv }
    let(:email) { 'theloneranger@texas.com' }
    let(:encoded_email) do
      CGI.escape(Base64.encode64(email))
    end
    subject { delete "/api/v3/subscriptions/#{listserv.id}/#{encoded_email}" }

    it 'returns 204 status' do
      subject
      expect(response).to have_http_status(204)
    end

    context 'when subscription exists matching email and listserv_id' do
      let(:subscription) do
        FactoryGirl.create :subscription,
                           listserv: listserv,
                           email: email,
                           unsubscribed_at: nil
      end

      it 'runs UnsubscribeSubscription' do
        expect(UnsubscribeSubscription).to receive(:call).with(subscription)
        subject
      end

      it 'sets unsubscribed_at' do
        expect do
          subject
        end.to change {
          subscription.reload.unsubscribed_at
        }.from(nil)
      end
    end
  end

  describe 'DELETE /api/v3/subscription/:key' do
    let!(:subscription) { FactoryGirl.create :subscription }

    subject { delete "/api/v3/subscriptions/#{subscription.key}" }

    it 'returns 204 status' do
      subject
      expect(response).to have_http_status(204)
    end

    it 'runs UnsubscribeSubscription' do
      expect(UnsubscribeSubscription).to receive(:call).with(subscription)
      subject
    end

    it 'sets unsubscribed_at' do
      expect do
        subject
      end.to change {
        subscription.reload.unsubscribed_at
      }.from(nil)
    end
  end

  describe 'POST /api/v3/subscriptions' do
    let(:listserv) { FactoryGirl.create :listserv }
    let(:user) { FactoryGirl.create :user }
    let(:unconfirmed_user) { FactoryGirl.create :user, confirmed_at: nil }
    let(:subscription_params) do
      { 'subscription' => { 'email' => user.email.to_s,
                            'name' => listserv.name.to_s, 'user_id' => nil, 'listserv_id' => listserv.id.to_s } }
    end
    let(:invalid_sub_params) do
      { 'subscription' => { 'id' => nil, 'email' => user.email.to_s, 'name' => listserv.name.to_s,
                            'listserv_id' => nil } }
    end
    subject { post '/api/v3/subscriptions', params: subscription_params }

    context 'with valid subscription attributes' do
      it 'responds with the correct status code' do
        subject
        expect(response.code).to eq '201'
      end

      it 'creates new subscription' do
        expect do
          subject
        end.to change { Subscription.count }.by(1)
      end

      it 'renders the the json for the new subscription' do
        subject
        expect(response_json[:subscription][:email]).to eq user.email
        expect(response_json[:subscription][:name]).to eq user.name
        expect(response_json[:subscription][:listserv_id]).to eq listserv.id
      end

      it 'can subscribe a user using listserv_id and email' do
        expect do
          post '/api/v3/subscriptions', params: { subscription: { listserv_id: listserv.id, email: user.email } }
        end.to change { Subscription.count }.by(1)
      end

      context 'when a user has confirmed their account' do
        it 'runs the SubscribeToListservSilently job' do
          request = double('request')
          allow(request).to receive(:remote_ip).and_return('127.0.0.1')
          expect(SubscribeToListservSilently).to receive(:call).with(listserv, user, request.remote_ip)
          subject
        end
      end

      context 'when a user has not confirmed their account' do
        before do
          @new_user_params = { 'subscription' =>
                                { 'listserv_id' => listserv.id,
                                  'email' => unconfirmed_user.email.to_s,
                                  'name' => listserv.name.to_s,
                                  'user_id' => nil } }
        end

        it 'subscribes to a listserv' do
          expect(SubscribeToListserv).to receive(:call).with(listserv, email: unconfirmed_user.email)
          post '/api/v3/subscriptions', params: @new_user_params
        end
      end

      context 'when listserv_id is present' do
        it 'creates new subscription' do
          expect do
            post '/api/v3/subscriptions', params: subscription_params.merge!(listserv_id: listserv.id)
          end.to change { Subscription.count }.by(1)
        end
      end

      context 'when the subscription request is from a user registration' do
        it 'creates a new subscription' do
          expect do
            post '/api/v3/subscriptions', params: subscription_params.merge!(subscribed_from_registration: true)
          end.to change { Subscription.count }.by(1)
        end

        it 'does not call the SubscribeToListserv jobs' do
          expect(SubscribeToListserv).to_not receive(:call).with(listserv, email: unconfirmed_user.email)
          expect(SubscribeToListservSilently).to_not receive(:call).with(listserv, email: unconfirmed_user.email)
          post '/api/v3/subscriptions', params: subscription_params.merge!(subscribed_from_registration: true)
        end
      end
    end

    context 'with invalid attributes' do
      subject { post '/api/v3/subscriptions', params: invalid_sub_params }

      it 'renders 422 status code' do
        subject
        expect(response.code).to eq '422'
      end

      it 'does not create a new subscription' do
        expect do
          subject
        end.to_not change {
          Subscription.count
        }
      end
    end
  end
end
