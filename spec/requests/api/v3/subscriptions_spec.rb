require 'rails_helper'

def json_datetime(dt)
  dt.try(:to_formatted_s, :iso8601)
end

RSpec.describe 'Subscriptions Endpoints', type: :request do
  describe 'GET /api/v3/unsubscribe_from_mailchimp' do
    it 'returns 200' do
      get '/api/v3/subscriptions/unsubscribe_from_mailchimp'
      expect(response.status).to eql 200
    end
  end

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
            expect(sub).to match(a_hash_including({
                                                    user_id: user.id,
                                                    id: a_kind_of(String),
                                                    listserv_id: a_kind_of(Integer),
                                                    email: a_kind_of(String),
                                                    name: a_kind_of(String),
                                                    email_type: a_kind_of(String),
                                                    created_at: a_kind_of(String),
                                                    confirmed_at: a_kind_of(String).or(be_nil),
                                                    unsubscribed_at: a_kind_of(String).or(be_nil)
                                                  }))
          end
        end

        it 'paginates' do
          url_params[:page] = 1
          url_params[:per_page] = 1

          subject

          expect(response_json[:subscriptions].count).to eql 1

          expect(response_json[:meta]).to match({
                                                  total_count: user_subscriptions.count,
                                                  page: 1,
                                                  per_page: 1,
                                                  page_count: 3
                                                })
        end
      end
    end
  end

  describe 'PATCH /api/v3/subscriptions/:key' do
    let(:subscription) { FactoryGirl.create :subscription, email_type: 'html' }
    let(:attrs) {
      {
        email_type: 'text',
        name: 'John Doe'
      }
    }

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

      expect(response_json[:subscription]).to match({
                                                      id: subscription.key,
                                                      email: subscription.email,
                                                      name: subscription.name,
                                                      listserv_id: subscription.listserv_id,
                                                      user_id: subscription.user_id,
                                                      created_at: json_datetime(subscription.created_at),
                                                      confirmed_at: json_datetime(subscription.confirmed_at),
                                                      email_type: subscription.email_type,
                                                      unsubscribed_at: json_datetime(subscription.unsubscribed_at)
                                                    })
    end

    context 'subscription does not exist' do
      subject { get "/api/v3/subscriptions/#{SecureRandom.uuid}" }

      it 'returns 404 (not found)' do
        subject
        expect(response.status).to eql 404
      end
    end
  end

  describe 'PATCH /api/v3/subscriptions/:key/confirm' do
    let(:subscription) { FactoryGirl.create :subscription }

    subject { patch "/api/v3/subscriptions/#{subscription.key}/confirm" }

    context 'when already confirmed' do
      before do
        subscription.update! confirmed_at: Time.zone.now, confirm_ip: '192.168.1.0'
      end

      it 'returns 204 status' do
        subject
        expect(response).to have_http_status(204)
      end

      it 'does not change confirmed_at date' do
        expect { subject }.to_not change {
          subscription.reload.confirmed_at
        }
      end

      context 'when unsubscribed' do
        before do
          subscription.update unsubscribed_at: Time.zone.now
        end

        it 'unsets unsubscribed status' do
          expect { subject }.to change {
            subscription.reload.unsubscribed_at
          }.to(nil)
        end
      end
    end

    context 'not already confirmed' do
      let(:remote_ip) { '192.168.0.1' }
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(remote_ip)
      end

      it 'returns 204 status' do
        subject
        expect(response).to have_http_status(204)
      end

      it 'sets confirm_ip and confirmed_at' do
        expect { subject }.to change {
          subscription.reload.attributes.with_indifferent_access.slice(:confirm_ip, :confirmed_at)
        }.to a_hash_including({
                                confirm_ip: remote_ip,
                                confirmed_at: an_instance_of(ActiveSupport::TimeWithZone)
                              })
      end
    end
  end

  describe 'DELETE /api/v3/subscriptions/{listserv_id}/{base64_email}' do
    let(:listserv) { FactoryGirl.create :listserv }
    let(:email) { "theloneranger@texas.com" }
    let(:encoded_email) {
      CGI.escape(Base64.encode64(email))
    }
    subject { delete "/api/v3/subscriptions/#{listserv.id}/#{encoded_email}" }

    it 'returns 204 status' do
      subject
      expect(response).to have_http_status(204)
    end

    context 'when subscription exists matching email and listserv_id' do
      let(:subscription) {
        FactoryGirl.create :subscription,
                           listserv: listserv,
                           email: email,
                           unsubscribed_at: nil
      }

      it 'runs UnsubscribeSubscription' do
        expect(UnsubscribeSubscription).to receive(:call).with(subscription)
        subject
      end

      it 'sets unsubscribed_at' do
        expect {
          subject
        }.to change {
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
      expect {
        subject
      }.to change {
        subscription.reload.unsubscribed_at
      }.from(nil)
    end
  end

  describe 'POST /api/v3/subscriptions' do
    let(:listserv) { FactoryGirl.create :listserv }
    let(:user) { FactoryGirl.create :user }
    let(:unconfirmed_user) { FactoryGirl.create :user, confirmed_at: nil }
    let(:subscription_params) {
      { 'subscription' => { 'email' => "#{user.email}",
                            'name' => "#{listserv.name}", 'user_id' => nil, 'listserv_id' => "#{listserv.id}" } }
    }
    let(:invalid_sub_params) {
      { 'subscription' => { 'id' => nil, 'email' => "#{user.email}", 'name' => "#{listserv.name}",
                            'listserv_id' => nil } }
    }
    subject { post '/api/v3/subscriptions', params: subscription_params }

    context 'with valid subscription attributes' do
      it 'responds with the correct status code' do
        subject
        expect(response.code).to eq '201'
      end

      it 'creates new subscription' do
        expect {
          subject
        }.to change { Subscription.count }.by(1)
      end

      it 'renders the the json for the new subscription' do
        subject
        expect(response_json[:subscription][:email]).to eq user.email
        expect(response_json[:subscription][:name]).to eq user.name
        expect(response_json[:subscription][:listserv_id]).to eq listserv.id
      end

      it 'can subscribe a user using listserv_id and email' do
        expect {
          post '/api/v3/subscriptions', params: { subscription: { listserv_id: listserv.id, email: user.email } }
        }.to change { Subscription.count }.by(1)
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
                                  'email' => "#{unconfirmed_user.email}",
                                  'name' => "#{listserv.name}",
                                  'user_id' => nil } }
        end

        it 'subscribes to a listserv' do
          expect(SubscribeToListserv).to receive(:call).with(listserv, { email: unconfirmed_user.email })
          post '/api/v3/subscriptions', params: @new_user_params
        end
      end

      context 'when listserv_id is present' do
        it 'creates new subscription' do
          expect {
            post '/api/v3/subscriptions', params: subscription_params.merge!(listserv_id: listserv.id)
          }.to change { Subscription.count }.by(1)
        end
      end

      context 'when the subscription request is from a user registration' do
        it 'creates a new subscription' do
          expect {
            post '/api/v3/subscriptions', params: subscription_params.merge!(subscribed_from_registration: true)
          }.to change { Subscription.count }.by(1)
        end

        it 'does not call the SubscribeToListserv jobs' do
          expect(SubscribeToListserv).to_not receive(:call).with(listserv, { email: unconfirmed_user.email })
          expect(SubscribeToListservSilently).to_not receive(:call).with(listserv, { email: unconfirmed_user.email })
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
        expect {
          subject
        }.to_not change {
          Subscription.count
        }
      end
    end
  end
end
