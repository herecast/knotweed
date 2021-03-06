# frozen_string_literal: true

require 'spec_helper'

# we override Devise registrations controller to support UX2
# and need to test the custom behavior.
describe RegistrationsController, type: :controller do
  let!(:default_location) { FactoryGirl.create :location, city: 'Hartford', state: 'VT' }
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    user = FactoryGirl.build :user
    @user_attributes = {
      name: user.name,
      location_id: user.location.id,
      email: user.email,
      password: user.password,
      password_confirmation: user.password,
      handle: 'handle'
    }
  end

  describe 'POST create' do
    context 'with format JSON' do
      subject { post :create, format: :json, params: { user: @user_attributes } }

      let(:user) { User.find_by_email(@user_attributes[:email]) }

      it 'should respond with success' do
        subject
        expect(response).to be_successful
      end

      it 'should not respond with authentication token' do
        subject
        expect(JSON.parse(response.body)).to_not eq(
          'token' => user.authentication_token,
          'email' => user.email
        )
      end

      it 'should respond with message text' do
        subject
        expect(JSON.parse(response.body)).to eq(
          'message' => "Thank you! For security purposes, a message with a confirmation link has been sent to your email address. Please check your email and click on the link to activate your account. If the message hasn't appeared in a few minutes, please check your spam folder."
        )
      end

      it 'should generate confirmation email' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'should generate an email confirmation token' do
        subject
        expect(user.confirmation_token).to_not be_nil
        expect(user.confirmation_sent_at).to_not be_nil
      end

      describe 'invalid attributes' do
        before do
          @user_attributes.delete(:location_id)
        end

        it 'returns 422 status' do
          subject
          expect(response.status).to eql 422
        end

        it 'returns error messages in json' do
          subject
          expect(JSON.parse(response.body)).to have_key('errors')
        end
      end

      context 'when instant_signup is true' do
        before do
          FactoryGirl.create :location
        end

        subject { get :create, format: :json, params: { user: @user_attributes, instant_signup: true } }

        it 'returns confirmed user' do
          subject
          response_json = JSON.parse(response.body)
          expect(response_json['email']).to eq @user_attributes[:email]
          expect(response_json['token']).to be_truthy
        end

        it 'increases user count by 1' do
          expect { subject }.to change {
            User.count
          }.by 1
        end

        it 'calls to add user to Mailchimp master list' do
          expect(BackgroundJob).to receive(:perform_later).with(
            'Outreach::AddUserToMailchimpMasterList',
            'call',
            an_instance_of(User),
            new_blogger: true
          )
          subject
        end
      end
    end

    context 'mailer tests' do
      subject! { post :create, format: :json, params: { user: @user_attributes } }

      let(:mail) { ActionMailer::Base.deliveries.last }

      it 'should be sent to the correct user' do
        expect(mail.to).to eq [@user_attributes[:email]]
      end

      it 'should be sent from the correct account' do
        expect(mail.from).to eq ['noreply@herecast.us']
      end

      it 'should contain correct url' do
        if mail.body.encoded =~ %r{<a href=\"http://#{Figaro.env.default_consumer_host}/sign_up/confirm/([^"]+)">}
          expect(User.confirm_by_token(Regexp.last_match(1)).email).to eq @user_attributes[:email]
        else
          raise 'expected consumer app URI to match email body'
        end
      end
    end
  end
end
