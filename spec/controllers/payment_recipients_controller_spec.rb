# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentRecipientsController, type: :controller do
  before do
    @admin = FactoryGirl.create :admin
    sign_in @admin
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new' do
    let(:user) { FactoryGirl.create :user }
    subject! { get :new, params: { user_id: user.id } }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let(:user) { FactoryGirl.create :user }
    subject { post :create, params: params, format: :js }

    context 'with valid params' do
      let(:params) { { payment_recipient: { user_id: user.id } } }
      it 'creates a payment_recipient record' do
        expect { subject }.to change { PaymentRecipient.count }.by(1)
      end
    end
    
    context 'with invalid params' do
      let(:params) { { payment_recipient: { fake_param: 'fake' } } }
      it 'does not create a payment recipient' do
        expect { subject }.not_to change { PaymentRecipient.count }
      end
    end
  end

  describe 'GET #edit' do
    let!(:payment_recipient) { FactoryGirl.create :payment_recipient }
    subject! { get :edit, params: { id: payment_recipient.id } }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT #update' do
    let!(:payment_recipient) { FactoryGirl.create :payment_recipient }
    let(:org) { FactoryGirl.create :organization }
    let(:params) { { id: payment_recipient.id,
                             payment_recipient: { organization_id: org.id } } }
    subject { put :update, params: params, format: :js }

    it 'updates the record' do
      expect { subject }.to change { payment_recipient.reload.organization }.to(org)
    end

    context 'with invalid user id' do
      let(:invalid_user) { (User.maximum(:id) || 0) + 1 }
      let(:params) { { id: payment_recipient.id, payment_recipient: { user_id: invalid_user, organization_id: org.id } } }

      it 'should not change the record' do
        expect { subject }.not_to change { payment_recipient.reload.organization }
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:payment_recipient) { FactoryGirl.create :payment_recipient }
    subject { delete :destroy, params: { id: payment_recipient.id }, format: :js }

    it 'destroys the payment recipient' do
      expect { subject }.to change { PaymentRecipient.count }.by(-1)
    end
  end
end
