require 'rails_helper'

RSpec.describe 'TempUserCaptures API Endpoints' do
  describe 'POST /api/v3/temp_user_captures' do
    let!(:persisted_user) { FactoryGirl.create :user, email: 'old_user@email.com' }
    let(:user_params) { { name: 'Firstname Lastname', email: 'fake@subtext.org' } }
    context 'when email is associated with another user' do
      it 'does not persist the email' do
        expect{ 
          post '/api/v3/temp_user_captures', temp_user_capture: user_params.merge(email: "#{persisted_user.email}")
        }.to_not change{ TempUserCapture.count }
      end
    end

    context 'when email is for a new user' do
      it 'persistes the users name and email' do
        expect{ 
          post '/api/v3/temp_user_captures', temp_user_capture: user_params
        }.to change{ TempUserCapture.count }.by(1)
      end
    end
  end
end
