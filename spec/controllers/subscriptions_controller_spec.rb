# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  let(:listserv) { FactoryGirl.create :subtext_listserv }

  let(:valid_attributes) do
    {
      email: 'name@example.org',
      listserv_id: listserv.id
    }
  end

  describe 'GET #index' do
    it 'assigns all subscriptions as @subscriptions' do
      subscription = Subscription.create! valid_attributes.merge(
        confirmed_at: Time.now,
        confirm_ip: '1.1.1.1'
      )
      get :index, params: {}
      expect(assigns(:subscriptions)).to eq([subscription])
    end

    context 'when many subcriptions exist' do
      before do
        5.times do |i|
          FactoryGirl.create :subscription,
                             created_at: Time.current + i,
                             confirmed_at: Time.now,
                             confirm_ip: '1.1.1.1'
        end
      end

      it 'sorts them newest first' do
        get :index, params: {}
        expect(assigns(:subscriptions).first).to eql Subscription.order('created_at DESC').first
      end
    end
  end

  describe 'GET #show' do
    it 'assigns the requested subscription as @subscription' do
      subscription = Subscription.create! valid_attributes
      get :show, params: { id: subscription.to_param }
      expect(assigns(:subscription)).to eq(subscription)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested subscription as @subscription' do
      subscription = Subscription.create! valid_attributes
      get :edit, params: { id: subscription.to_param }
      expect(assigns(:subscription)).to eq(subscription)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Subscription' do
        expect do
          post :create, params: { subscription: valid_attributes }
        end.to change(Subscription, :count).by(1)
      end

      it 'assigns a newly created subscription as @subscription' do
        post :create, params: { subscription: valid_attributes }
        expect(assigns(:subscription)).to be_a(Subscription)
        expect(assigns(:subscription)).to be_persisted
      end

      it 'redirects to the subscription list' do
        post :create, params: { subscription: valid_attributes }
        expect(response).to redirect_to(subscriptions_url)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { blacklist: true }
      end

      it 'updates the requested subscription' do
        subscription = Subscription.create! valid_attributes
        put :update, params: { id: subscription.to_param, subscription: new_attributes }
        subscription.reload
        expect(subscription.blacklist?).to eql true
      end

      it 'assigns the requested subscription as @subscription' do
        subscription = Subscription.create! valid_attributes
        put :update, params: { id: subscription.to_param, subscription: valid_attributes }
        expect(assigns(:subscription)).to eq(subscription)
      end

      it 'redirects to the subscription list' do
        subscription = Subscription.create! valid_attributes
        put :update, params: { id: subscription.to_param, subscription: valid_attributes }
        expect(response).to redirect_to(subscriptions_url)
      end
    end

    context 'with invalid params' do
      before do
        @subscription = FactoryGirl.create :subscription
      end

      subject { put :update, params: { id: @subscription.id, subscription: { email: nil } } }

      it 'does not update subscription' do
        initial_state = @subscription.clone
        subject
        expect(@subscription.reload).to eq initial_state
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested subscription' do
      subscription = Subscription.create! valid_attributes
      expect do
        delete :destroy, params: { id: subscription.to_param }
      end.to change(Subscription, :count).by(-1)
    end

    it 'redirects to the subscriptions list' do
      subscription = Subscription.create! valid_attributes
      delete :destroy, params: { id: subscription.to_param }
      expect(response).to redirect_to(subscriptions_url)
    end
  end
end
