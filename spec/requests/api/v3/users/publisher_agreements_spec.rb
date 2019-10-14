require 'spec_helper'

RSpec.describe 'User Publisher Agreements endpoint', type: :request do
  describe '/api/v3/users/:user_id/publisher_agreements' do
    before do
      @user = FactoryGirl.create :user,
        publisher_agreement_confirmed: false,
        publisher_agreement_confirmed_at: nil,
        publisher_agreement_version: nil
      mail = double(deliver_later: true)
      allow(PublishersMailer).to receive(
        :publisher_agreement_confirmation
      ).and_return(mail)
    end

    let(:auth_headers) { auth_headers_for(@user) }

    subject { post "/api/v3/users/#{@user.id}/publisher_agreements", headers: auth_headers }

    it "updates publisher agreement flags" do
      expect{ subject }.to change{
        @user.reload.publisher_agreement_confirmed
      }.to(true).and change{
        @user.reload.publisher_agreement_confirmed_at
      }.and change{
        @user.reload.publisher_agreement_version
      }
    end
  end
end