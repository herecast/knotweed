require 'rails_helper'

RSpec.describe FeaturesController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    Feature.destroy_all
  end

  let(:valid_attrs) { {name: 'My Feature',
    description: 'Feature Description',
    active: false
  } }

  describe 'GET #index' do
    it 'assigns all features as @features' do
      feature = Feature.create!(valid_attrs)
      get :index
      expect(assigns(:features)).to eq([feature])
    end
  end

  describe 'GET #new' do
    it 'assigns a new feature as @feature' do
      get :new
      expect(assigns(:feature)).to be_a_new(Feature)
    end
  end

  describe 'GET #edit' do
    it 'assigns the correct feature as @feature' do
      feature = Feature.create!(valid_attrs)
      get :edit, { :id => feature.id }
      expect(assigns(:feature)).to eq(feature)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new feature flag' do
        expect {
          post :create, { :feature => valid_attrs }
        }.to change(Feature, :count).by(1)
      end

      it 'redirects back to the index page' do
        post :create, { :feature => valid_attrs }
        expect(response).to redirect_to(features_path)
      end
    end

    context 'with invalid params' do
      it 'does not create a new feature flag' do
        post :create, { :feature => { name: nil } }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attrs) { { name: 'My Special Feature'} }

      it 'updates the feature properly' do
        feature = Feature.create! valid_attrs
        put :update, { :id => feature.to_param, :feature => new_attrs }
        feature.reload
        expect(feature.name).to eq 'My Special Feature'
      end

      it 'assigns the requested feature as @feature' do
        feature = Feature.create! valid_attrs
        put :update, { :id => feature.to_param, :feature => valid_attrs }
        expect(assigns(:feature)).to eq feature
      end

      it 'redirects to the index' do
        feature = Feature.create valid_attrs
        put :update, { :id => feature.to_param, :feature => valid_attrs }
        expect(response).to redirect_to(features_url)
      end
    end
  end
end