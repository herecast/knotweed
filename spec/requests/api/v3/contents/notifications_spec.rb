# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Content Notifications Endpoints", type: :request do

  describe "POST /api/v3/contents/:content_id/notifications" do
    before do
      @user = FactoryGirl.create :user
      @content = FactoryGirl.create :content, :news,
        mc_campaign_id: nil,
        created_by_id: @user.id
    end

    let(:auth_headers) { auth_headers_for(@user) }

    subject do
      post "/api/v3/contents/#{@content.id}/notifications",
      headers: auth_headers
    end

    it "calls to send notification" do
      expect(BackgroundJob).to receive(:perform_later).with(
        'Outreach::SendOrganizationPostNotification',
        'call',
        @content
      )
      subject
    end

    context "when Content mc_campaign_id is not nil" do
      before do
        @content.update_attribute(:mc_campaign_id, 'njksnd')
      end

      it "does not call to send notification" do
        expect(BackgroundJob).not_to receive(:perform_later)
        subject
      end
    end
  end
end