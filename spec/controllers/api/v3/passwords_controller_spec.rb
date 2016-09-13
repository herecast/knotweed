require 'spec_helper'

describe Api::V3::PasswordsController, :type => :controller do
  before do
    @user = FactoryGirl.create :user
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST /password_resets' do

    context 'with existing user\'s email address' do
      subject { post :create, user: { email: @user.email } }

      it 'should send an email to the user' do
        expect{subject}.to change{ActionMailer::Base.deliveries.count}.by(1)
      end

      it 'should generate a reset_password_token and set reset_password_sent_at' do
        subject
        @user.reload
        expect(@user.reset_password_token.present?).to be true
      end

      context 'with return_url' do
        subject { post :create, user: { email: @user.email }, return_url: 'http://test.com' }

        it 'should send email with link including return_url ' do
          subject
          last_email = ActionMailer::Base.deliveries.last
          expect(last_email.body.encoded).to include('http://test.com')
        end
      end
    end

  end

  describe 'PUT /password_resets' do
    before do
      # generate valid password reset token
      @token = @user.send_reset_password_instructions
      @orig_pass = @user.encrypted_password
    end

    context 'with valid token' do
      subject! { put :update, user: { reset_password_token: @token, password: 'newPassword',
                                     password_confirmation: 'newPassword' } }

      it 'should update the user\'s password' do
        expect(@user.reload.encrypted_password).not_to eq(@orig_pass)
      end

      it 'should respond 204 no content' do
        expect(response.status).to eql 204
      end
    end

    context 'with invalid token' do
      subject! { put :update, user: { reset_password_token: 'fake token', password: 'Whatever',
                                      password_confirmation: 'Whatever' } }

      it 'should not update the user\'s password' do
        expect(@user.reload.encrypted_password).to eq(@orig_pass)
      end

      it 'should respond with 422' do
        expect(response.code).to eq('422')
      end
    end

  end
end
