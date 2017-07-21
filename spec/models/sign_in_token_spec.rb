# == Schema Information
#
# Table name: sign_in_tokens
#
#  id         :integer          not null, primary key
#  token      :string           not null
#  user_id    :integer
#  created_at :datetime         not null
#

require 'rails_helper'

RSpec.describe SignInToken, type: :model do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:user) }
  end

  describe 'token' do
    it 'gets generated when initialized' do
      expect(SignInToken.new.token).to be_a_kind_of String
    end

    context 'uniqueness' do
      it 'generates random and unique keys each time' do
        tokens = 5.times.collect{ SignInToken.new.token }

        expect(tokens.uniq).to eql tokens
      end
    end
  end

  describe '.authenticate' do
    context 'some recent tokens exist' do
      let(:tokens) { FactoryGirl.create_list :sign_in_token, 3, created_at: 23.hours.ago }

      it 'returns the user associated with a particular token' do
        user = SignInToken.authenticate(tokens.second.token)

        expect(user).to eql tokens.second.user
      end

      context 'token is older than 24 hours' do
        before do
          tokens.second.update created_at: 24.hours.ago - 1.minute
        end

        it 'returns nil' do
          user = SignInToken.authenticate(tokens.second.token)

          expect(user).to be_nil
        end
      end
    end
  end

  describe '.clean_stale' do
    context 'tokens exist which are expired' do
      let!(:non_expired_token) { FactoryGirl.create :sign_in_token }
      let!(:expired_tokens) { FactoryGirl.create_list :sign_in_token, 3, created_at: 26.hours.ago }

      it 'removes expired tokens only' do
        SignInToken.clean_stale!

        expect(SignInToken.all.to_a).to eql [non_expired_token]
      end
    end
  end
end
