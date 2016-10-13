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

      subject { get '/api/v3/subscriptions', url_params, auth_headers }

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

    subject { patch "/api/v3/subscriptions/#{subscription.key}", subscription: attrs }

    it 'will update email_type' do
      expect{ subject }.to change{
        subscription.reload.email_type
      }.to 'text'
    end

    it 'will update name' do
      expect{ subject }.to change{
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
        subscription.update! confirmed_at: Time.now, confirm_ip: '192.168.1.0'
      end

      it 'returns 200 status' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'does not change confirmed_at date' do
        expect{ subject }.to_not change{
          subscription.reload.confirmed_at
        }
      end

      context 'when unsubscribed' do
        before do
          subscription.update unsubscribed_at: Time.now
        end

        it 'unsets unsubscribed status' do
          expect{ subject }.to change{
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

      it 'returns 200 status' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'runs ConfirmSubscription process' do
        expect(ConfirmSubscription).to receive(:call).with(subscription, remote_ip)
        subject
      end
    end
  end

  describe 'PATCH /api/v3/subscriptions/:key/unsubscribe' do
    let(:subscription) { FactoryGirl.create :subscription }

    subject { patch "/api/v3/subscriptions/#{subscription.key}/unsubscribe" }

    context 'when already unusbscribed' do
      before do
        subscription.update unsubscribed_at: Time.now
      end

      it 'returns 200 status' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'does not change unsubscribed_at date' do
        expect{ subject }.to_not change{
          subscription.reload.unsubscribed_at
        }
      end

      it 'runs UnsubscribeSubscription' do
        expect(UnsubscribeSubscription).to receive(:call).with(subscription)
        subject
      end
    end

    context 'not already unsubscribed' do
      it 'returns 200 status' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'sets unsubscribed_at' do
        expect{
          subject
        }.to change{
          subscription.reload.unsubscribed_at
        }.from(nil)
      end
    end
  end
end
