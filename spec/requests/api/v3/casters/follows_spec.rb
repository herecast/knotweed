# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organization Subscriptions Endpoints', type: :request do
  let(:caster) { FactoryGirl.create :caster }
  let(:user) { FactoryGirl.create :user }
  let(:headers) { auth_headers_for(user) }

  describe 'POST /api/v3/casters/:caster_id/follows' do
    before do
      allow(Outreach::CreateOrganizationSubscriptionInMailchimp).to receive(
        :call
      ).and_return true
    end

    subject { post "/api/v3/casters/#{caster.id}/follows", headers: headers }

    it 'creates OrganizationSubscription' do
      expect { subject }.to change {
        OrganizationSubscription.count
      }.by 1
    end

    it 'calls to create subscription in Mailchimp' do
      expect(Outreach::CreateOrganizationSubscriptionInMailchimp).to receive(
        :call
      )
      subject
    end
  end

  describe 'DELETE /api/v3/casters/follows/:id' do
    before do
      @caster_follow = FactoryGirl.create :caster_follow,
        user_id: user.id,
        caster_id: caster.id
      allow(Outreach::DestroyOrganizationSubscriptionInMailchimp).to receive(
        :call
      ).and_return true
    end

    subject { delete "/api/v3/casters/follows/#{@caster_follow.id}", headers: headers }

    it 'calls to destroy subscription in Mailchimp' do
      expect(Outreach::DestroyOrganizationSubscriptionInMailchimp).to receive(
        :call
      ).with(@caster_follow)
      subject
    end
  end
end
