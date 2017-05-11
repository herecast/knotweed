require 'rails_helper'

RSpec.describe RemoveExpiredTokensJob do
  let!(:expired_tokens) { FactoryGirl.create_list :sign_in_token, 3, created_at: 2.days.ago }
  let!(:current_token) { FactoryGirl.create :sign_in_token }
  subject { described_class.new.perform }

  it 'removes all tokens created more than 24 hrs ago' do
    expect{ subject }.to change{ SignInToken.count }.by(-3)
  end
end
