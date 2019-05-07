# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe Api::V3::UsersController, type: :controller do
  describe 'GET current_user' do
    describe 'when user not signed in' do
      before { api_authenticate success: false }
      it 'should respond with 401 unuthorized' do
        get :show, format: :json
        expect(response.code).to eq('401')
      end
    end

    describe 'when api user signed in' do
      before do
        google_logo_stub

        listserv = FactoryGirl.create :listserv
        location = FactoryGirl.create :location, listservs: [listserv], \
                                                 consumer_active: true
        @user = FactoryGirl.create :user, location: location
        allow(@user).to receive(:avatar_url).and_return(
          'https://www.google.com/images/srpr/logo11w.png'
        )
        api_authenticate user: @user
      end

      subject! { get :show, format: :json }

      it 'should respond with 200' do
        expect(response.code).to eq('200')
      end

      it 'should return expected fields' do
        desired = expected_user_response @user
        expect(JSON.parse(response.body)).to match desired
      end
    end
  end

  describe 'PUT current_user' do
    describe 'when user not signed in' do
      before { api_authenticate success: false }
      it 'should respond with 401 unauthorized' do
        put :update, format: :json
        expect(response.code).to eq('401')
      end
    end

    describe 'change user attributes' do
      before do
        listserv = FactoryGirl.create :listserv
        location = FactoryGirl.create :location, listservs: [listserv], \
                                                 consumer_active: true
        @user = FactoryGirl.create :user, location: location
        api_authenticate user: @user
        @new_data = { format: :json,
                      current_user: {
                        user_id: @user.id.to_s,
                        name: 'Skye Bill',
                        location_id: location.slug,
                        location_confirmed: true,
                        email: 'skye@bill.com',
                        password: 'snever4aet3',
                        password_confirmation: 'snever4aet3',
                        public_id: 'aleteatk-atjkata'
                      } }
      end

      subject! { put :update, params: @new_data }

      it 'should update fields' do
        updated_user = controller.current_user
        expect(updated_user.name).to eq @new_data[:current_user][:name]
        expect(updated_user.location).to eq Location.find_by_slug_or_id @new_data[:current_user][:location_id]
        expect(updated_user.location_confirmed?).to be true
        expect(updated_user.public_id).to eq @new_data[:current_user][:public_id]

        expect(updated_user.unconfirmed_email).to eq @new_data[:current_user][:email]
        expect(updated_user.encrypted_password).not_to eq @new_data[:current_user][:encrypted_password]
        expect(response.code).to eq '200'
      end

      it 'should respond with current_user GET data' do
        # change the test user name to editted name before comparison
        @user.name = @new_data[:current_user][:name]
        expect(JSON.parse(response.body)).to match expected_user_response @user.reload
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
                        location_id: location.id,
                        user_id: @user.id.to_s
                      } }
      end

      subject! { put :update, params: @new_data }

      it 'should not update all fields' do
        updated_user = controller.current_user
        expect(updated_user.name).to eq @new_data[:current_user][:name]
        expect(updated_user.location).to eq Location.find @new_data[:current_user][:location_id]

        expect(updated_user.email).to eq @user.email
        expect(updated_user.encrypted_password).to eq @user.encrypted_password
        expect(response.code).to eq '200'
      end
    end

    describe 'when update fails' do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
        @new_data = { format: :json,
                      current_user: {
                        password: 'p1',
                        password_confirmation: 'we',
                        user_id: @user.id.to_s
                      } }
      end

      subject! { put :update, params: @new_data }

      it 'should provide appropriate reponse' do
        updated_user = controller.current_user
        expect(response.code).to eq '422'
      end
    end

    describe 'set user avatar' do
      before do
        @user = FactoryGirl.create :user, avatar: nil
        api_authenticate user: @user
      end

      subject! { put :update, format: :json, params: { current_user: { user_id: @user.id, image: file } } }

      context 'when image is improper type' do
        let!(:file) { fixture_file_upload('/bad_upload_file.json', 'application/javascript') }

        it "returns 'failed' alert" do
          decoded_response = JSON.parse(response.body)
          expect(response.status).to eq 422
          expect(decoded_response['messages'].size).to eq 1
        end
      end

      context 'when image is proper type' do
        %w[jpg jpeg png].each do |extension|
          let!(:file) { fixture_file_upload("/photo.#{extension}", "image/#{extension}") }

          it "should set new image from file type #{extension}" do
            expect(response.status).to eq 200
            expect(controller.current_user.avatar_identifier).to include(file.original_filename)
          end
        end
      end
    end
  end

  private

  def expected_user_response(user)
    { current_user:
      {
        id: user.id,
        name: user.name,
        email: user.email,
        created_at: user.created_at.iso8601,
        location: {
          id: user.location.id,
          city: user.location.city,
          state: user.location.state
        }.stringify_keys,
        location_confirmed: user.location_confirmed,
        listserv_name: user.location.listserv.name,
        listserv_id: user.location.listserv.id,
        test_group: user.test_group,
        user_image_url: user.avatar.url,
        skip_analytics: false,
        can_publish_news: false,
        managed_organization_ids: [],
        has_had_bookmarks: user.has_had_bookmarks,
        is_blogger: user.has_role?(:blogger),
        organization_subscriptions: user.organization_subscriptions.map do |os|
          {
            id: os.id,
            organization_name: os.organization.name
          }
        end,
        organization_hides: []
      }.stringify_keys }.stringify_keys
  end
end
