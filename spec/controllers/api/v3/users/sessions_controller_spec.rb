# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::Users::SessionsController, type: :controller do

  describe 'POST destroy' do
    context do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
      end

      subject! { post :destroy, format: :json }

      it 'should logout user' do
        expect(controller.current_user).to be_nil
        expect(response.code).to eq '200'
      end
    end

    context do
      before do
        @user = FactoryGirl.create :user
        @orig_token = @user.authentication_token
        api_authenticate user: @user
      end

      subject! { post :destroy, format: :json }

      it 'should change authentication token' do
        expect(@user.reload.authentication_token).not_to eq @orig_token
      end
    end
  end

end
