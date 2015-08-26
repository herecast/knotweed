require 'spec_helper'
require 'json'

describe Api::V3::UsersController do
  describe 'GET current_user' do
    
    describe 'when user not signed in' do
      before { api_authenticate success: false }
      it 'should respond with 401 unuthorized' do
        get :show, format: :json
        response.code.should eq('401')
      end
    end

    describe 'when api user signed in' do
      before do
        listserv = FactoryGirl.create :listserv
        location = FactoryGirl.create :location, listservs: [listserv], \
          consumer_active: true
        @user = FactoryGirl.create :user, location: location
        api_authenticate user: @user
      end

      subject! { get :show, format: :json }

      it 'should respond with 200' do
        response.code.should eq('200')
      end

      it 'should return expected fields' do
       desired = { current_user: {
          id: @user.id,
          name: @user.name,
          email: @user.email,
          created_at: @user.created_at,
          location: @user.location.name,
          listserv_name: @user.location.listserv.name, 
          listserv_id: @user.location.listserv.id,
          test_group: @user.test_group || "",
          user_image_url: "" }.stringify_keys
        }.stringify_keys
        desired.should eq JSON.parse(response.body)
      end
    end

  end


  describe 'POST current_user' do
    describe 'when user not signed in' do
      before { api_authenticate success: false }
      it 'should respond with 401 unuthorized' do
        post :update, format: :json
        response.code.should eq('401')
      end
    end
  end


end
