require 'rails_helper'

RSpec.describe PaymentRecipientsController, type: :controller do
  before do
    @admin = FactoryGirl.create :admin
    sign_in @admin
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    let(:user) { FactoryGirl.create :user }
    subject! { get :new, params: { user_id: user.id } }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    let(:user) { FactoryGirl.create :user }
    subject { post :create, params: { payment_recipient: { user_id: user.id } }, format: :js }

    it 'creates a payment_recipient record' do
      expect { subject }.to change { PaymentRecipient.count }.by(1)
    end
  end

  describe "GET #edit" do
    let!(:payment_recipient) { FactoryGirl.create :payment_recipient }
    subject! { get :edit, params: { id: payment_recipient.id } }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT #update" do
    let!(:payment_recipient) { FactoryGirl.create :payment_recipient }
    let(:org) { FactoryGirl.create :organization }
    subject {
      put :update, params: { id: payment_recipient.id,
                             payment_recipient: { organization_id: org.id } }, format: :js
    }

    it "updates the record" do
      expect { subject }.to change { payment_recipient.reload.organization }.to(org)
    end
  end

  describe "DELETE #destroy" do
    let!(:payment_recipient) { FactoryGirl.create :payment_recipient }
    subject { delete :destroy, params: { id: payment_recipient.id }, format: :js }

    it "destroys the payment recipient" do
      expect { subject }.to change { PaymentRecipient.count }.by(-1)
    end
  end
end
