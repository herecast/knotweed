require 'rails_helper'

RSpec.describe SubscriptionsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  let(:listserv) {FactoryGirl.create :subtext_listserv}

  let(:valid_attributes) {{
    email: "name@example.org",
    listserv_id: listserv.id
  }}

  describe "GET #index" do
    it "assigns all subscriptions as @subscriptions" do
      subscription = Subscription.create! valid_attributes
      get :index, {}
      expect(assigns(:subscriptions)).to eq([subscription])
    end

    context 'when many subcriptions exist' do
      before do
        5.times do
          FactoryGirl.create :subscription
          sleep 0.2
        end
      end

      it 'sorts them newest first' do
        get :index, {}
        expect(assigns(:subscriptions).first).to eql Subscription.order('created_at DESC').first
      end
    end
  end

  describe "GET #show" do
    it "assigns the requested subscription as @subscription" do
      subscription = Subscription.create! valid_attributes
      get :show, {:id => subscription.to_param}
      expect(assigns(:subscription)).to eq(subscription)
    end
  end

  describe "GET #edit" do
    it "assigns the requested subscription as @subscription" do
      subscription = Subscription.create! valid_attributes
      get :edit, {:id => subscription.to_param}
      expect(assigns(:subscription)).to eq(subscription)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Subscription" do
        expect {
          post :create, {:subscription => valid_attributes}
        }.to change(Subscription, :count).by(1)
      end

      it "assigns a newly created subscription as @subscription" do
        post :create, {:subscription => valid_attributes}
        expect(assigns(:subscription)).to be_a(Subscription)
        expect(assigns(:subscription)).to be_persisted
      end

      it "redirects to the subscription list" do
        post :create, {:subscription => valid_attributes}
        expect(response).to redirect_to(subscriptions_url)
      end
    end

  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {blacklist: true}
      }

      it "updates the requested subscription" do
        subscription = Subscription.create! valid_attributes
        put :update, {:id => subscription.to_param, :subscription => new_attributes}
        subscription.reload
        expect(subscription.blacklist?).to eql true
      end

      it "assigns the requested subscription as @subscription" do
        subscription = Subscription.create! valid_attributes
        put :update, {:id => subscription.to_param, :subscription => valid_attributes}
        expect(assigns(:subscription)).to eq(subscription)
      end

      it "redirects to the subscription list" do
        subscription = Subscription.create! valid_attributes
        put :update, {:id => subscription.to_param, :subscription => valid_attributes}
        expect(response).to redirect_to(subscriptions_url)
      end
    end

  end

  describe "DELETE #destroy" do
    it "destroys the requested subscription" do
      subscription = Subscription.create! valid_attributes
      expect {
        delete :destroy, {:id => subscription.to_param}
      }.to change(Subscription, :count).by(-1)
    end

    it "redirects to the subscriptions list" do
      subscription = Subscription.create! valid_attributes
      delete :destroy, {:id => subscription.to_param}
      expect(response).to redirect_to(subscriptions_url)
    end
  end

end