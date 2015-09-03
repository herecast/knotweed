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
        #raw_resp = File.new("spec/fixtures/google_logo_resp.txt")
        #stub_request(:get, "https://www.google.com/images/srpr/logo11w.png").       with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        #to_return(raw_resp.read)
        #ImageUploader.storage = :file

        listserv = FactoryGirl.create :listserv
        location = FactoryGirl.create :location, listservs: [listserv], \
          consumer_active: true
        @user = FactoryGirl.create :user, location: location
        #@user.avatar = FactoryGirl.create :image, remote_image_url: "https://www.google.com/images/srpr/logo11w.png", imageable_id: @user.id, imageable_type: 'User'
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
          created_at: @user.created_at.strftime("%Y-%m-%dT%H:%M:%S%:z"),
          location_id: @user.location.id,
          location: @user.location.name,
          listserv_name: @user.location.listserv.name, 
          listserv_id: @user.location.listserv.id,
          test_group: @user.test_group || "",
          user_image_url: "" }.stringify_keys
        }.stringify_keys
          JSON.parse(response.body).should eq desired
      end
    end

  end


  describe 'PUT current_user' do
      describe 'when user not signed in' do
        before { api_authenticate success: false }
        it 'should respond with 401 unuthorized' do
          put :update, format: :json
          response.code.should eq('401')
        end
      end

      describe 'change user attributes' do
        before do
          location = FactoryGirl.create :location
          @user = FactoryGirl.create :user
          api_authenticate user: @user
          @new_data = { format: :json,
                        current_user: {
                          name: 'Skye Bill',
                          location_id: location.id ,
                          email: 'skye@bill.com',
                          password: 'snever4aet3',
                          password_confirmation: 'snever4aet3'
                          }
                      }
        end

        subject! { put :update, @new_data } 

        it 'should update fields' do
          updated_user = assigns(:current_api_user)
          updated_user.name.should eq @new_data[:current_user][:name]
          updated_user.location.should eq Location.find @new_data[:current_user][:location_id]
          
          updated_user.unconfirmed_email.should eq @new_data[:current_user][:email]
          updated_user.encrypted_password.should_not eq @new_data[:current_user][:encrypted_password]
          response.code.should eq '200'
        end

      end

      describe 'change only some attributes' do
        before do
          location = FactoryGirl.create :location
          @user = FactoryGirl.create :user
          api_authenticate user: @user
          @new_data = { format: :json,
                        current_user: {
                          name: 'Skye2 Bill',
                          location_id: location.id
                          }
                      }
        end

        subject! { put :update, @new_data } 

        it 'should not update all fields' do
          updated_user = assigns(:current_api_user)
          updated_user.name.should eq @new_data[:current_user][:name]
          updated_user.location.should eq Location.find @new_data[:current_user][:location_id]
          
          updated_user.email.should eq @user.email
          updated_user.encrypted_password.should eq @user.encrypted_password
          response.code.should eq '200'
        end

      end

      describe 'when update fails' do
        before do
          @user = FactoryGirl.create :user
          api_authenticate user: @user
          @new_data = { format: :json,
                        current_user: {
                          password: 'p1',
                          password_confirmation: 'we'
                          }
                      }
        end

        subject! { put :update, @new_data } 

        it 'should provide appropriate reponse' do
          updated_user = assigns(:current_api_user)
          response.code.should eq '422'
        end

      end

  end


end