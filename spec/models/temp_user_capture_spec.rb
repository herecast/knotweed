require 'rails_helper'

RSpec.describe TempUserCapture, type: :model do
  it { is_expected.to have_db_column(:name) }
  it { is_expected.to have_db_column(:email) }

  describe '#new_user?' do
    let!(:persisted_user) { FactoryGirl.create :user }

    it 'is not valid if the temp_users email already has a user account' do
      subject.email = persisted_user.email
      subject.valid?
      expect(subject.errors.count).to eq 1
    end

    it 'is valid if email belongs to a new user' do
      subject.email = "new_user@subtext.org"
      subject.valid?
      expect(subject.errors.count).to eq 0
    end
  end
end
