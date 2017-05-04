require 'rails_helper'
require 'rake'

describe 'temp_users namespace rake task' do
  describe 'temp_users:register' do

    let(:subject) { Rake::Task["temp_users:register"] }
    before do
      load File.expand_path("../../../../lib/tasks/temp_users.rake", __FILE__)
      Rake::Task.define_task(:environment)
      FactoryGirl.create :location, city: 'Hartford'
    end

    it 'handles duplicates in the TempUserCapture table' do
      temp_user = TempUserCapture.create(name: Faker::Name.name, email: 'testuser@email.com')
      TempUserCapture.create(name: Faker::Name.name, email: temp_user.email)
      expect{ subject.execute }.to change{ User.count }.from(0).to(1)
    end

    it 'creates the new users' do
      FactoryGirl.create_list :temp_user_capture, 3
      expect{ subject.execute }.to change{ User.count }.by(3)
    end



    it 'removes the temp users from the table' do
      FactoryGirl.create_list :temp_user_capture, 3
      expect{ subject.execute }.to change{ TempUserCapture.count }.from(3).to(0)
    end

    it 'sends the email with the correct stuff' do
      FactoryGirl.create :temp_user_capture
      confirmation_email = instance_double(ActionMailer::MessageDelivery)
      expect(StreamlinedRegistrationMailer).to receive(:confirmation_instructions).with(any_args).and_return(confirmation_email)
      allow(confirmation_email).to receive(:deliver_later)
      subject.execute
    end

    it 'does not delete temp users who register while task is running' do
      FactoryGirl.create_list :temp_user_capture, 3
      mid_registration_user = TempUserCapture.create(name: Faker::Name.name, email: 'mid-registration@email.com')
      mid_registration_user.update_attribute(:created_at, Time.zone.now + 5.minutes)
      expect{ subject.execute }.to change{ TempUserCapture.count }.from(4).to(1)
    end
  end
end

