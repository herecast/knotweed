require 'spec_helper'

RSpec.describe Listservs::TestsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe "POST create" do
    context "when no listserv present" do
      before do
        @listserv = FactoryGirl.create :listserv
        @digest = Outreach::BuildDigest.call(@listserv)
        allow(Outreach::BuildDigest).to receive(:call).with(
          @listserv
        ).and_return @digest
      end

      subject { post :create, listserv_id: @listserv.id }

      it "calls to build and send test digest" do
        expect(Outreach::BuildDigest).to receive(:call).with(
          @listserv
        )
        expect(BackgroundJob).to receive(:perform_later).with(
          'Outreach::TestDigest', 'call', { user: @user, digest: @digest }
        )
        subject
      end
    end
  end
end