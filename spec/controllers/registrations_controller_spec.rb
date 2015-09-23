require 'spec_helper'

# we override Devise registrations controller to support UX2
# and need to test the custom behavior.
describe RegistrationsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST create' do

    context 'with format JSON' do
      before(:each) do
        @user_attributes = {
          name: 'My Name',
          location_id: FactoryGirl.create(:location).id,
          email: 'test@testing.com',
          password: 'password',
          password_confirmation: 'password'
        }
      end

      subject!{ post :create, format: :json, user: @user_attributes }

      let(:user) { User.find_by_email(JSON.parse(response.body)['email']) }

      it 'should respond with success' do
        expect(response).to be_success
      end

      it 'should set NDA fields' do
        expect(user.nda_agreed_at.present?).to be true
        expect(user.agreed_to_nda).to be true
      end
        
      it 'should respond with token' do
        expect(JSON.parse(response.body)).to eq({
          'token' => user.authentication_token,
          'email' => user.email
        })
      end

    end
  end
end
