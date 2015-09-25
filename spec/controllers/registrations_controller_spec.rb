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
        user = FactoryGirl.build :user
        @user_attributes = {
          name: user.name,
          location_id: user.location.id,
          email: user.email,
          password: user.password,
          password_confirmation: user.password
        }
      end

      subject{ post :create, format: :json, user: @user_attributes }

      let(:user) { User.find_by_email(@user_attributes[:email]) }

      it 'should respond with success' do
        subject
        expect(response).to be_success
      end

      it 'should set NDA fields' do
        subject
        expect(user.nda_agreed_at.present?).to be true
        expect(user.agreed_to_nda).to be true
      end
        
      it 'should not respond with authentication token' do
        subject
        expect(JSON.parse(response.body)).to_not eq({
          'token' => user.authentication_token,
          'email' => user.email
        })
      end

      it 'should respond with message text' do
        subject
        expect(JSON.parse(response.body)).to eq({
          'message' => "Thank you! For security purposes, a message with a confirmation link has been sent to your email address. Please check your email and click on the link to activate your account. If the message hasn't appeared in a few minutes, please check your spam folder."
        })
      end

      it 'should generate confirmation email' do
        expect{subject}.to change{ActionMailer::Base.deliveries.count}.by(1)
      end

      it 'should generate an email confirmation token' do
        subject
        expect(user.confirmation_token).to_not be_nil
        expect(user.confirmation_sent_at).to_not be_nil
      end
    end

    context 'mailer tests' do
      before do
        user = FactoryGirl.build :user
        @user_attributes = {
          name: user.name,
          location_id: user.location.id,
          email: user.email,
          password: user.password,
          password_confirmation: user.password
        }
        @consumer_app = FactoryGirl.create :consumer_app
      end
      
      subject! do 
        request.env['Consumer-App-Uri'] = @consumer_app.uri
        post :create, format: :json, user: @user_attributes
      end
      
      def mail
        @mail ||= ActionMailer::Base.deliveries.last
      end
      
      it 'should be sent to the correct user' do
        mail.to.should eq [@user_attributes[:email]]
      end

      it 'should be sent from the correct account' do
        mail.from.should eq ['noreply@subtext.org']
      end

      it 'should contain correct url' do
        if mail.body.encoded =~ %r{<a href=\"#{@consumer_app.uri}/sign_up/confirm/([^"]+)">}
          User.confirm_by_token($1).email.should eq @user_attributes[:email]
        else
          raise 'expected consumer app URI to match email body'
        end
      end
    end
  end
end
