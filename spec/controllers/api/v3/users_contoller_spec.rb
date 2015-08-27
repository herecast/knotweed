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
    
        # Stub out image requests
        raw_resp = File.new("spec/fixtures/google_logo_resp.txt")
        stub_request(:get, "https://www.google.com/images/srpr/logo11w.png").       with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(raw_resp.read)
        ImageUploader.storage = :file

        listserv = FactoryGirl.create :listserv
        location = FactoryGirl.create :location, listservs: [listserv], \
          consumer_active: true
        image = FactoryGirl.create :image, remote_image_url: "https://www.google.com/images/srpr/logo11w.png", imageable: @user
        @user = FactoryGirl.create :user, location: location, avatar: image
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
          user_image_url: @user.avatar.image.url }.stringify_keys
        }.stringify_keys
          JSON.parse(response.body).should eq desired
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
