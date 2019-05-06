# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::SubscriptionsController, type: :controller do
  describe 'POST update' do
    before do
      @user = FactoryGirl.create :user
      @listserv = FactoryGirl.create :listserv

      @sub_attrs = { subscription: {
        user_id: @user.id,
        listserv_id: @listserv.id,
        source: 'daily_uv',
        email: @user.email,
        name: @user.name,
        confirmed_at: Time.zone.now,
        email_type: 'html'
      } }
    end
    subject { post :create, params: @sub_attrs, format: :json }

    it 'responds successfully' do
      subject
      expect(response.code).to eq '201'
    end

    it 'creates a new subscription' do
      subject
      expect(assigns(:subscription)).to be_a Subscription
    end

    it 'sets confirmed_at and confirmation_ip' do
      subject
      expect(assigns(:subscription).confirmed_at).to_not be_nil
      expect(assigns(:subscription).confirm_ip).to_not be_nil
    end

    it 'silently subscribes a user to the listserv' do
      expect(SubscribeToListservSilently).to receive(:call).with(@listserv, @user, '0.0.0.0')
      subject
    end

    it 'returns errors for invalid subscriptions' do
      @sub_attrs = { subscription: {
        user_id: @user.id,
        source: 'daily_uv',
        email: @user.email,
        name: @user.name,
        confirmed_at: Time.zone.now,
        email_type: 'html'
      } }

      post :create, params: @sub_attrs, format: :json
      expect(response.code).to eq '422'
    end

    it 'silently re-subscribes a user to the listserv' do
      expect(SubscribeToListservSilently).to receive(:call).with(@listserv, @user, '0.0.0.0')
      subject
    end

    context 'when a user re-subscribes' do
      it 'handles already persisted subscriptions' do
        @subscription = Subscription.create(@sub_attrs[:subscription])
        subject
        expect(response.code).to eq '201'
      end

      it 'resubscribes existing subscriptions' do
        @subscription = Subscription.create(@sub_attrs[:subscription].merge(unsubscribed_at: Time.zone.now))
        subject
        expect(assigns(:subscription).unsubscribed_at).to be_nil
      end
    end
  end
end
