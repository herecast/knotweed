require 'rails_helper'

RSpec.describe RegisterTempUsersJob do

  describe 'perform' do

    before do
      temp_user = FactoryGirl.create :temp_user_capture
      dup_temp_user = FactoryGirl.create :temp_user_capture
      user_after_temp_capture = FactoryGirl.create :user, email: dup_temp_user.email
      FactoryGirl.create :location, city: "Hartford"
    end
    
    it 'registers users from the TempUserCaptureTable' do
      expect{subject.perform}.to change{User.count}.by(1)
    end

  end

end
