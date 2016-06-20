require 'spec_helper'
require 'json'

describe Api::V3::UsersController, :type => :controller do
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
        @user.remote_avatar_url = "https://www.google.com/images/srpr/logo11w.png"
        @user.save
        api_authenticate user: @user
      end

      subject! { get :show, format: :json }

      it 'should respond with 200' do
        expect(response.code).to eq('200')
      end

      it 'should return expected fields' do
       desired = expected_user_response @user 
       expect(JSON.parse(response.body)).to eq desired
      end
    end

  end

  describe 'PUT current_user' do
      describe 'when user not signed in' do
        before { api_authenticate success: false }
        it 'should respond with 401 unuthorized' do
          put :update, format: :json
          expect(response.code).to eq('401')
        end
      end

      context 'when user_id does not match current_user.id' do
        before do
          @user = FactoryGirl.create :user
          api_authenticate user: @user
          @new_data = { format: :json,
                        current_user: {
                          user_id: @user.id + 11,
                          name: 'Jane Jones III'
                        }
                      }
        end
        
        subject! { put :update, @new_data }

        it 'should not update user' do
          expect(response.code).to eq '422'
          expect(assigns(:current_api_user).name).to eq @user.name
          expect(assigns(:current_api_user).name).not_to eq @new_data[:current_user][:name]
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
                          location_id: location.id ,
                          email: 'skye@bill.com',
                          password: 'snever4aet3',
                          password_confirmation: 'snever4aet3',
                          public_id: 'aleteatk-atjkata'
                          }
                      }
        end

        subject! { put :update, @new_data } 

        it 'should update fields' do
          updated_user = assigns(:current_api_user)
          expect(updated_user.name).to eq @new_data[:current_user][:name]
          expect(updated_user.location).to eq Location.find @new_data[:current_user][:location_id]
          expect(updated_user.public_id).to eq @new_data[:current_user][:public_id]
          
          expect(updated_user.unconfirmed_email).to eq @new_data[:current_user][:email]
          expect(updated_user.encrypted_password).not_to eq @new_data[:current_user][:encrypted_password]
          expect(response.code).to eq '200'
        end

        it 'should respond with current_user GET data' do
          #change the test user name to editted name before comparison
          @user.name = @new_data[:current_user][:name]  
          expect(JSON.parse(response.body)).to eq expected_user_response @user
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
                          }
                      }
        end

        subject! { put :update, @new_data } 

        it 'should not update all fields' do
          updated_user = assigns(:current_api_user)
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
                          }
                      }
        end

        subject! { put :update, @new_data } 

        it 'should provide appropriate reponse' do
          updated_user = assigns(:current_api_user)
          expect(response.code).to eq '422'
        end

      end

      describe 'set user avatar' do
        before do
          @user = FactoryGirl.create :user
          # just in case this gets set in the factory in the future
          @user.avatar = nil
          @user.save

          api_authenticate user: @user
        end

        subject! { put :update, format: :json, current_user: {user_id: @user.id.to_s, image: file} }

        context "when image is improper type" do
          let!(:file) { fixture_file_upload('/bad_upload_file.json', 'application/javascript') }

          it "returns 'failed' alert" do
            decoded_response = JSON.parse(response.body)
            expect(response.status).to eq 422
            expect(decoded_response["messages"].size).to eq 1
          end
        end

        context "when image is proper type" do
          ['jpg', 'jpeg', 'png'].each do |extension|
            let!(:file) { fixture_file_upload("/photo.#{extension}", "image/#{extension}") }

            it "should set new image from file type #{extension}" do
              expect(response.status).to eq 200
              expect(assigns(:current_api_user).avatar_identifier).to include(file.original_filename)
            end
          end
        end
      end

  end

  describe 'GET weather' do
    before do
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      # we're not really testing whether ForecastIO or the gem works here, so just stub
      # this method completely to avoid it making HTTP requests
      allow(ForecastIO).to receive(:forecast).and_return({})
    end

    subject { get :weather }

    context 'not signed in' do
      it 'should set location to default location' do
        subject
        expect(assigns(:location)).to eq(@default_location)
      end
    end

    context 'signed in' do
      before do
        @other_loc = FactoryGirl.create :location
        @user = FactoryGirl.create :user, location: @other_loc
        api_authenticate user: @user
      end

      it 'should set location to the user\'s location' do
        subject
        expect(assigns(:location)).to eq(@other_loc)
      end
    end
  end
  
  describe 'GET events' do
    context 'with valid public id' do
      before do
        @public_id = 'slomo'
        user = FactoryGirl.create :user, public_id: @public_id
        content = FactoryGirl.create :content, created_by: user
        event = FactoryGirl.create :event, content: content
        FactoryGirl.create :schedule, event: event
      end
      
      subject! { get :events, format: :ics, public_id: @public_id }

      it 'should return ics data' do
        expect(@response.body).to match /VCALENDAR/
        expect(@response.body).to match /DTSTART/
        expect(@response.body).to match /DTSTAMP/
        expect(@response.body).to match /VEVENT/
        expect(@response.body).to match /RRULE/
        expect(@response.body).to match /VTIMEZONE/
      end
    end

    context 'with invalid public id' do
      before { @user = FactoryGirl.create :user }
      subject! { get :events, format: :ics, public_id: 'fake-ekaf' }
      it { expect(@response.status).to eq 404 }
    end
  end
   
  describe 'ical url' do
    context 'when user has public id'  do
      before do 
        @user = FactoryGirl.create :user, public_id: 'sorlara'
        @consumer = FactoryGirl.create :consumer_app, uri: Faker::Internet.url
        api_authenticate user: @user, consumer_app: @consumer
      end

      subject! { get :show }

      it 'should contain the ical url' do
        expect(JSON.parse(@response.body)['current_user']['events_ical_url']).to eq @consumer.uri + user_event_instances_ics_path(@user.public_id)
      end
    end

    context 'when user has no public id' do
      before do 
        @user = FactoryGirl.create :user, public_id: ''
        @consumer = FactoryGirl.create :consumer_app, uri: Faker::Internet.url
        api_authenticate user: @user, consumer_app: @consumer
      end

      subject! { get :show, format: :json }

      it 'should contain the ical url' do
        expect(JSON.parse(@response.body)['current_user']['events_ical_url']).to be_nil
      end
    end
  end

  describe 'POST logout' do
    context do 
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
      end

      subject! { post :logout , format: :json}

      it 'should logout user' do
        expect(assigns(:current_user)).to be_nil
        expect(assigns(:current_api_user)).to be_nil
        expect(response.code).to eq '200'
      end
    end

    context do
      before do
        @user = FactoryGirl.create :user
        @orig_token = @user.authentication_token
        api_authenticate user: @user
      end

      subject! { post :logout , format: :json}

      it 'should change authentication token' do
        expect(@user.reload.authentication_token).not_to eq @orig_token 
      end
    end
  end
  
  describe 'POST email_confirmation' do
    before do
      @user = FactoryGirl.create :user, confirmed_at: nil
    end
    context 'with valid confirmation token' do
      # we have to call instance_variable_get to pull the raw token that's included in the email. confirmation_token in the DB is the encrypted version.
      subject! { post :email_confirmation, confirmation_token: @user.instance_variable_get(:@raw_confirmation_token), format: :json}
      
      it 'should respond with auth token' do
        expect(JSON.parse(response.body)).to eq({token: @user.authentication_token,
                                             email: @user.email
                                         }.stringify_keys)
      end
    end

    context 'with invalid confirmation token' do
      subject! { post :email_confirmation, confirmation_token: 'fake', format: :json }
      
      it 'should respond with 404' do
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST resend_confirmation' do
    before do
      @user = FactoryGirl.create :user, confirmed_at: nil
    end
    
    context 'with a valid unconfirmed account' do
      subject { post :resend_confirmation, user: { email: @user.email } }

      it 'should trigger sending an email' do
        expect{subject}.to change{ActionMailer::Base.deliveries.count}.by 1
      end
    end

    context 'with an email not associated with any accounts' do
      subject! { post :resend_confirmation, user: { email: 'does_not_exist@indatabase.com' } }

      it 'should respond with 404 status' do
        expect(response.code).to eq('404')
      end
    end

    context 'with an already confirmed account' do
      before do
        @user.confirm
      end

      subject! { post :resend_confirmation, user: { email: @user.email } }

      it 'should respond with a message saying the user is already confirmed' do
        expect(response.body).to include('already confirmed')
      end
    end

  end

  private
    
    def expected_user_response(user)
       { current_user: {
          id: user.id,
          name: user.name,
          email: user.email,
          created_at: user.created_at.iso8601,
          location_id: user.location.id,
          location: user.location.name,
          listserv_name: user.location.listserv.name,
          listserv_id: user.location.listserv.id,
          test_group: user.test_group,
          user_image_url: user.avatar.url,
          skip_analytics: false,
          events_ical_url: nil,
          can_publish_news: false,
          managed_organization_ids: []}.stringify_keys,
        }.stringify_keys
    end
end
