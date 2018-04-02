require 'rails_helper'
require 'aescrypt'

RSpec.describe 'Register Confirmed User', type: :request do
  describe 'POST /api/v3/registrations/confirmed' do
    context 'Given new user details;' do
      let(:user_details) {
        {
          email: "test@example.org",
          password: "123456jkl&",
          location_id: FactoryGirl.create(:location).id,
          name: "John Smith"
        }
      }

      subject { post "/api/v3/registrations/confirmed", registration: user_details }

      context 'Given confirmation key matching existing subscription' do
        let(:subscription) { FactoryGirl.create(:subscription, user_id: nil) }
        before do
          user_details[:confirmation_key] = "subscription/#{subscription.key}"
        end

        it 'returns 201 status' do
          subject
          expect(response.status).to eql 201
        end

        it 'creates a user record' do
          expect{ subject }.to change{
            User.last
          }
        end

        it 'sets user to confirmed' do
          subject
          expect(User.last).to be_confirmed
        end

        it 'returns authentication token and email' do
          subject
          expect(response_json).to match(
            email: user_details[:email],
            token: instance_of(String)
          )

          token = response_json[:token]
          expect(token).to eql User.last.authentication_token
        end

        context 'when no location_id supplied' do
          before do
            user_details[:location_id] = nil
          end

          it 'sets default location' do
            subject
            expect(User.last.location).to be_a Location
          end
        end

        context "when no password supplied" do
          before do
            user_details[:password] = nil
          end

          it 'creates a temporary password for user, unencyrptable by confirmation_key' do
            subject
            user = User.last
            temp_pw = AESCrypt.decrypt(user.temp_password, user_details[:confirmation_key])
            expect(user).to be_valid_password(temp_pw)
          end
        end
      end

      describe 'Invalid confirmation_key;' do
        context 'invalid format' do
          before do
            user_details[:confirmation_key] = "This is not valid"
          end

          it 'returns 422 status' do
            subject
            expect(response.status).to eql 422
          end
        end

        context 'valid format, not real record' do
          before do 
            user_details[:confirmation_key] = 'content/01234567'
          end

          it 'returns 422 status' do
            subject
            expect(response.status).to eql 422
          end
        end

        context 'no confirmation_key' do
          before do 
            user_details[:confirmation_key] = nil
          end

          it 'returns 422 status' do
            subject
            expect(response.status).to eql 422
          end
        end
      end
    end
  end
end
